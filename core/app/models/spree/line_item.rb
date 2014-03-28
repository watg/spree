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

    after_save :update_inventory
    after_save :update_order
    after_destroy :update_order

    delegate :name, :description, :should_track_inventory?, to: :variant

    attr_accessor :target_shipment

    def add_personalisations(collection)
      objects = collection.map do |o|
        # o is an OpenStruct which maps to directly to LineItemPersonalisation 
        # hence we can use marshal_dump as we are lazy
        Spree::LineItemPersonalisation.new o.marshal_dump
      end
      self.line_item_personalisations = objects
    end

    def add_parts(collection)
      objects = collection.map do |o|
        # o is an OpenStruct which maps to directly to LineItemPart 
        # hence we can use marshal_dump as we are lazy
        Spree::LineItemPart.new o.marshal_dump
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
      d { line_item_parts.blank? }
      d {amount_all_parts }
      ( line_item_parts.blank? ? 0 : amount_all_parts ) +
      ( line_item_personalisations.blank? ? 0 : amount_all_personalisations ) 
    end

    def amount_all_parts
      d { self.line_item_parts.first.price }
      d { self.line_item_parts.first.quantity }
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
      result = Spree::Stock::Quantifier.can_supply_order?(self.order, self)
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

  end
end

