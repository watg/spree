module Spree
  class LineItem < ActiveRecord::Base
    before_validation :adjust_quantity

    belongs_to :order, class_name: "Spree::Order", inverse_of: :line_items, touch: true
    belongs_to :variant, class_name: "Spree::Variant", inverse_of: :line_items
    belongs_to :tax_category, class_name: "Spree::TaxCategory"
    belongs_to :target, class_name: "Spree::Target"

    belongs_to :product_page, class_name: "Spree::ProductPage"
    belongs_to :product_page_tab, class_name: "Spree::ProductPageTab"

    has_one :product, through: :variant

    has_many :adjustments, as: :adjustable, dependent: :destroy
    has_many :inventory_units, inverse_of: :line_item

    has_many :line_item_personalisations, dependent: :destroy
    alias personalisations line_item_personalisations

    has_many :line_item_parts#, dependent: :destroy
    alias parts line_item_parts

    before_validation :copy_price
    before_validation :copy_tax_category

    validates :variant, presence: true
    validates :quantity, numericality: {
      only_integer: true,
      greater_than: -1,
      message: Spree.t('validation.must_be_int')
    }
    validates :price, numericality: true
    validates_with Stock::AvailabilityValidator

    validate :ensure_proper_currency
    before_destroy :update_inventory

    after_destroy :destroy_line_item_parts

    def destroy_line_item_parts
      self.line_item_parts.destroy_all
    end

    # Destroy and verify inventory so that units are restocked back to the
    # stock location
    def destroy_along_with_units
      self.quantity = 0
      OrderInventory.new(self.order, self).verify
      self.destroy
    end

    after_save :update_inventory
    after_save :update_adjustments

    after_create :create_tax_charge

    delegate :name, :description, :should_track_inventory?, to: :variant

    attr_accessor :options_with_qty
    attr_accessor :target_shipment

    scope :digital, lambda { joins(variant: [ product: [ :product_type ] ] ).merge( Spree::ProductType.where( is_digital: true ) ) }
    scope :physical, lambda { joins(variant: [ product: [ :product_type ] ] ).merge( Spree::ProductType.where( is_digital: false ) ) }

    scope :operationl, lambda { joins(variant: [ product: [ :product_type ] ] ).merge( Spree::ProductType.where( is_operational: true ) ) }
    scope :not_operational, lambda { joins(variant: [ product: [ :product_type ] ] ).merge( Spree::ProductType.where( is_operational: false ) ) }

    class << self
      def without(line_item)
        where.not(id: line_item.try(:id))
      end
    end

    def copy_price
      if variant
        self.price = variant.price if price.nil?
        self.cost_price = variant.cost_price if cost_price.nil?
        self.currency = order.currency if currency.nil?
      end
    end

    def copy_tax_category
      if variant
        self.tax_category = variant.tax_category
      end
    end

    def has_gift_card?
      self.product.product_type.gift_card?
    end

    def base_price
      price - options_and_personalisations_price
    end

    def base_normal_price
      (normal_price || price) - options_and_personalisations_price
    end

    # price includes Optional Parts and Personalisations
    def amount
      price * quantity
    end
    alias subtotal amount

    def discounted_amount
      amount + promo_total
    end

    def final_amount
      amount + adjustment_total.to_f
    end
    alias total final_amount

    # normal price includes Optional Parts and Personalisations
    def normal_amount
      (normal_price || price) * quantity
    end
    alias normal_total normal_amount

    def options_and_personalisations_price
      ( line_item_parts.blank? ? 0 : amount_all_parts ) +
        ( line_item_personalisations.blank? ? 0 : amount_all_personalisations )
    end

    def amount_all_parts
      list_amount = self.line_item_parts.select{|e| e.optional }.map {|e| e.price * e.quantity}
      list_amount.inject(0){|s,a| s += a; s}
    end

    def amount_all_personalisations
      list_amount = self.line_item_personalisations.map {|p| p.amount }
      list_amount.sum
    end

    def assembly_selected_variants
      return unless variant.assembly_definition

      line_item_parts.inject({}) do |hsh, option|
        hsh[option.assembly_definition_part_id] = option.variant_id
        hsh
      end
    end

    def single_money
      Spree::Money.new(price, { currency: currency })
    end
    alias single_display_amount single_money

    def money
      Spree::Money.new(amount, { currency: currency })
    end
    alias display_total money
    alias display_amount money

    def normal_display_amount
      Spree::Money.new(normal_amount, { currency: currency })
    end

    def sale_display_amount
      if in_sale?
        display_amount
      else
        normal_display_amount
      end
    end

    def adjust_quantity
      self.quantity = 0 if quantity.nil? || quantity < 0
    end

    def sufficient_stock?
      Spree::Stock::AvailabilityValidator.new.validate(self)
      self.errors.blank?
    end

    def insufficient_stock?
      !sufficient_stock?
    end

    def assign_stock_changes_to=(shipment)
      @preferred_shipment = shipment
    end

    # Remove product default_scope `deleted_at: nil`
    def product
      variant.product
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { super }
    end

    def item_sku
      sku_parts = self.line_item_parts.required.map { |p| p.variant.sku }
      suffix = sku_parts.any? ? " [#{sku_parts.sort.join(', ')}]" : ''
      self.variant.sku + suffix
    end

    def weight
      value_for(:weight)
    end

    def cost_price
      value_for(:cost_price)
    end

    private

    def value_for(attribute)
      (self.variant.send(attribute).to_f + options_value_for(attribute)) * self.quantity
    end

    def options_value_for(attribute)
      self.line_item_parts.reduce(0.0) do |w, o|
        value = o.variant.send(attribute)
        if value.blank?
          Rails.logger.warn("The #{attribute} of variant id: #{o.variant.id} is nil for line_item_part: #{o.id}")
          value = BigDecimal.new(0,2)
        end
        w + ( value.to_f * o.quantity )
      end
    end

    def update_inventory
      #There is a quirk where the after_create hook which run's before after_save is saving the
      #line_item in a nested model callback, hence by the time changed? is evaluated it is false
      #if changed?
      Spree::OrderInventory.new(self.order, self).verify(target_shipment)
      #end
    end

    def update_adjustments
      if quantity_changed?
        recalculate_adjustments
      end
    end

    def recalculate_adjustments
      Spree::ItemAdjustments.new(self).update
    end

    def create_tax_charge
      Spree::TaxRate.adjust(order, [self])
    end

    def ensure_proper_currency
      unless currency == order.currency
        errors.add(:currency, :must_match_order_currency)
      end
    end

  end
end

