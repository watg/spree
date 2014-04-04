module Spree
  class LineItem < ActiveRecord::Base
    before_validation :adjust_quantity
    belongs_to :order, class_name: "Spree::Order", :inverse_of => :line_items
    belongs_to :variant, class_name: "Spree::Variant"

    belongs_to :tax_category, class_name: "Spree::TaxCategory"
    belongs_to :target, class_name: "Spree::Target"

    has_one :product, through: :variant

    has_many :adjustments, as: :adjustable, dependent: :destroy
    has_many :inventory_units
    has_many :line_item_personalisations, dependent: :destroy
    alias personalisations line_item_personalisations
    has_many :line_item_parts, dependent: :destroy
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

    before_destroy :update_inventory

    after_save :update_inventory
    after_save :update_order
    after_destroy :update_order

    delegate :name, :description, :should_track_inventory?, to: :variant

    attr_accessor :options_with_qty
    attr_accessor :target_shipment

    def add_personalisations(collection)
      objects = collection.map do |o|
        Spree::LineItemPersonalisation.new(
          line_item: self,
          personalisation_id: o.personalisation_id,
          amount: o.amount || BigDecimal.new(0),
          data: o.data
        )
      end
      self.line_item_personalisations = objects
    end

    def add_parts(collection)
      objects = collection.map do |o|
        Spree::LineItemPart.new(
          line_item: self,
          quantity: o.quantity,
          price: o.price || BigDecimal.new(0),
          assembly_definition_part_id: o.assembly_definition_part_id,
          variant_id: o.variant_id,
          optional: o.optional,
          currency: o.currency
        )
      end
      self.line_item_parts = objects
    end

    def copy_price
      if variant
        self.price = variant.price if price.nil?
        self.cost_price = variant.cost_price if cost_price.nil?
        self.currency = variant.currency if currency.nil?
      end
    end

    def price_without_tax
      amount_without_tax = price - ( amount / order.item_total ) * order.tax_total
      BigDecimal.new(amount_without_tax).round(2, BigDecimal::ROUND_HALF_UP)
    end

    def copy_tax_category
      if variant
        self.tax_category = variant.product.tax_category
      end
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
    alias total amount

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

    def adjust_quantity
      self.quantity = 0 if quantity.nil? || quantity < 0
    end

    def sufficient_stock?
      result = Spree::Stock::Quantifier.can_supply_order?(self.order)
      result[:in_stock]
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
      definition = self.variant.assembly_definition
      if definition
        definition.parts.map do |part|
          option = self.line_item_parts.where(optional: false, assembly_definition_part_id: part.id).first
          "#{part.product.name} - #{option.variant.options_text}" if option
        end.compact.join(', ')
      else
        self.variant.sku
      end
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
        # We only want to notify if we are part of an assembly e.g. we are a line_item_part and we have a nil as 
        # a price
        if value.blank? 
          notify("The #{attribute} of variant id: #{o.variant.id} is nil for line_item_part: #{o.id}")
          value = BigDecimal.new(0,2)
        end

        w + ( value.to_f * o.quantity )
      end
    end

    def notify(msg)
      # Sends an email to Techadmin
      NotificationMailer.send_notification(msg)
    end

    def update_inventory
      if changed?
        Spree::OrderInventory.new(self.order, self).verify(target_shipment)
      end 
    end

    def update_order
      if changed? || destroyed?
        # update the order totals, etc.
        order.create_tax_charge!
        order.update!
      end
    end

  end
end

