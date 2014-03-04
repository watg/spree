module Spree
  class LineItem < ActiveRecord::Base
    before_validation :adjust_quantity
    belongs_to :order, class_name: "Spree::Order"
    belongs_to :variant, class_name: "Spree::Variant"
    belongs_to :tax_category, class_name: "Spree::TaxCategory"
    belongs_to :target, class_name: "Spree::Target"

    has_one :product, through: :variant
    has_many :adjustments, as: :adjustable, dependent: :destroy
    has_many :line_item_personalisations, dependent: :destroy

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

    before_save :set_item_uuid
    after_save :update_inventory
    after_save :update_order
    after_destroy :update_order

    delegate :name, :description, :should_track_inventory?, to: :variant

    attr_accessor :target_shipment

    def self.generate_uuid( variant, options_with_qty, personalisations )
      [ 
        variant.id,
        Spree::LineItemPersonalisation.generate_uuid( personalisations ),
        Spree::LineItemOption.generate_uuid( options_with_qty ),
      ].join('_')
    end

    def add_personalisations(collection)
      objects = collection.map do |params|
        Spree::LineItemPersonalisation.new params
      end
      self.line_item_personalisations = objects
    end

    def copy_price
      if variant
        self.price = variant.price if price.nil?
        self.cost_price = variant.cost_price if cost_price.nil?
        self.currency = variant.currency if currency.nil?
      end
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
      ( line_item_options.blank? ? 0 : amount_all_options ) +
      ( line_item_personalisations.blank? ? 0 : amount_all_personalisations ) 
    end

    def amount_all_options
      list_amount = self.line_item_options.
        select{|e| e.optional }.
        map {|e|   e.price * e.quantity}
      list_amount.inject(0){|s,a| s += a; s}
    end

    def amount_all_personalisations
      list_amount = self.line_item_personalisations.map {|p| p.amount }
      list_amount.sum
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
      Stock::Quantifier.new(variant_id).can_supply? quantity
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

    private
    def update_inventory
      if changed?
        # We do not call self.product as when save is called on the line_item object it for some reason
        # causes the product to update due to the has_one through variant relationship
        if variant.product.can_have_parts?
          Spree::OrderInventoryAssembly.new(self).verify(self, target_shipment)
        else
          Spree::OrderInventory.new(self.order).verify(self, target_shipment)
        end 
      end 
    end

    def update_order
      if changed? || destroyed?
        # update the order totals, etc.
        order.create_tax_charge!
        order.update!
      end
    end

    def set_item_uuid
      self.item_uuid = generate_uuid
    end

    def generate_uuid
      options_with_qty = line_item_options.map do |o|
        [o.variant, o.quantity]
      end

      personalisations_params = line_item_personalisations.map do |p|
        { data: p.data, personalisation_id: p.personalisation_id }
      end

      self.class.generate_uuid( variant, options_with_qty, personalisations_params )
    end

  end
end

