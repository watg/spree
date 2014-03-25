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
      list_amount = self.line_item_options.select{|e| e.optional }.map {|e| e.price * e.quantity}
      list_amount.inject(0){|s,a| s += a; s}
    end

    def amount_all_personalisations
      list_amount = self.line_item_personalisations.map {|p| p.amount }
      list_amount.sum
    end

    def assembly_selected_variants
      return unless variant.assembly_definition

      line_item_options.inject({}) do |hsh, option|
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
          option = self.line_item_options.where(optional: false, assembly_definition_part_id: part.id).first
          "#{part.product.name} - #{option.variant.options_text}" if option
        end.compact.join(', ')
      else
        self.variant.sku
      end
    end

    def weight
      if self.variant.static_kit? 
        (static_kit_weight + options_weight) * self.quantity
      else
        (self.variant.weight.to_f + options_weight) * self.quantity
      end
    end

    def cost_price
      if self.variant.static_kit? 
        (static_kit_cost_price + options_cost_price) * self.quantity
      else
        (self.variant.cost_price.to_f + options_cost_price) * self.quantity
      end
    end

    private

    def options_cost_price
      self.line_item_options.reduce(0.0) do |w, o|

        cost_price = o.variant.cost_price
        # We only want to notify if we are part of an assembly e.g. we are a line_item_option and we have a nil as 
        # a price
        if cost_price.blank? 
          notify("The weight of variant id: #{o.variant.id} is nil for line_item_option: #{o.id}")
          cost_price = BigDecimal.new(0,2)
        end

        w + ( cost_price.to_f * o.quantity )
      end
    end

    def static_kit_cost_price
      kit_cost_price = self.variant.required_parts_for_display.inject(0.00) do |sum,part|
        count_part = part.count_part 
        part_cost_price = part.cost_price 
        notify("Variant id #{part.try(:id)} has no cost_price") unless part_cost_price
        sum + (count_part * part_cost_price.to_f)
      end
      kit_cost_price
    end

    def options_weight
      self.line_item_options.reduce(0.0) do |w, o|

        weight = o.variant.weight
        # We only want to notify if we are part of an assembly e.g. we are a line_item_option and we have a nil as 
        # a price
        if weight.blank? 
          notify("The weight of variant id: #{o.variant.id} is nil for line_item_option: #{o.id}")
          weight = BigDecimal.new(0,2)
        end

        w + ( weight.to_f * o.quantity )
      end
    end

    def static_kit_weight
      kit_weight = self.variant.required_parts_for_display.inject(0.00) do |sum,part|
        count_part = part.count_part 
        part_weight = part.weight 
        notify("Variant id #{part.try(:id)} has no weight") unless part_weight
        sum + (count_part * part_weight.to_f)
      end
      kit_weight
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

