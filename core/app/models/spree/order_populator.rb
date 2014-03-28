module Spree
  class OrderPopulator
    attr_accessor :order, :currency
    attr_reader :errors

    class << self
      def parse_options(variant, options)
        return [] if options.blank?
        assembly_definition_parts = variant.product.assembly_definition.parts
        options.inject([]) do |list, t| 
          part_id, selected_variant_id = t.flatten.map(&:to_i)
          assembly_definition_part = assembly_definition_parts.detect{|p| p.id == part_id}
          
          if assembly_definition_part && (selected_variant_id > 0)
            selected_variant_part = Spree::Variant.find(selected_variant_id)
            list << [selected_variant_part, assembly_definition_part.count, assembly_definition_part.optional, assembly_definition_part.id]
          end
          
          list
        end
      end
    end

    def initialize(order, currency)
      @order = order
      @currency = currency
      @errors = ActiveModel::Errors.new(self)
    end

    #
    # Parameters can be passed using the following possible parameter configurations:
    #
    # * Single variant/quantity pairing
    # +:variants => { variant_id => quantity }+
    #
    # * Multiple products at once
    #   **** This is the pattern that we use ****
    #   ** - pp_ids need to be moved out of the products hash
    #
    #  :products => { product_id => variant_id, product_id => variant_id, pp_ids = [] },
    #  :quantity => quantity+, 
    #  :target_id => 2
    #  :options => [56, 34] # array of variant_ids
    #  ....
    def populate(from_hash)
      # product_assembly
      options = extract_kit_options(from_hash)
      personalisations = extract_personalisations(from_hash)

      target_id = from_hash[:target_id]
      # Coearce the target_id to nil if it is blank, as this makes find_by( target_id: target_id ) 
      # behave as target_id is actually a integer in the DB
      target_id = nil if target_id.blank?

      from_hash[:products].each do |product_id,variant_id|
        attempt_cart_add(variant_id, from_hash[:quantity], options, personalisations, target_id)
      end if from_hash[:products]

      from_hash[:variants].each do |variant_id, quantity|
        attempt_cart_add(variant_id, quantity, options, personalisations, target_id )
      end if from_hash[:variants]

      valid?
    end

    def valid?
      errors.empty?
    end

    private

    # product_assembly
    def extract_kit_options(hash)
      value = hash[:products].delete(:options) rescue nil
      # If we have parts then we have a new dynamic kit
      # and we should not have options, hence overwrite them
      value = hash.delete(:parts) if hash[:parts]
      (value || [])
    end

    # This will return an array of hashes in case
    # we have multiple personalisations
    # "enabled_pp_ids" => ["65"],  # personalisation_id
    # "pp_ids" => {
    #   "65"=>{
    #     "colour"=>"2", 
    #     "initials"=>"XXXX"
    #   }
    # }

    def extract_personalisations(hash)
      return unless hash[:products]
      enabled_pp_ids = hash[:products].delete(:enabled_pp_ids) || []
      pp_ids = hash[:products].delete(:pp_ids) || {}
      enabled_pp_ids.map do |pp_id|
        params = pp_ids[pp_id]
        pp = Spree::Personalisation.find pp_id
        safe_params = pp.validate( params )
        {
          personalisation_id: pp_id, 
          amount: pp.prices[currency],
          data: safe_params
        }
      end
    end

    # This has modifications for options and personalisations
    def attempt_cart_add(variant_id, quantity, option_ids=[], personalisations=[], target_id)
      quantity = quantity.to_i
      # 2,147,483,647 is crazy.
      # See issue #2695.
      if quantity > 2_147_483_647
        errors.add(:base, Spree.t(:please_enter_reasonable_quantity, :scope => :order_populator))
        return false
      end
      variant = Spree::Variant.find(variant_id)
      options_with_qty = add_quantity_for_each_option(variant, option_ids)

      if quantity > 0
        if check_stock_levels_for_variant_and_options(variant, quantity, options_with_qty)
          shipment = nil
          line_item = @order.contents.add(variant, quantity, currency, shipment, options_with_qty, personalisations, target_id)
          unless line_item.valid?
            errors.add(:base, line_item.errors.messages.values.join(" "))
            return false
          end
        end
      end
    end

    def check_stock_levels_for_variant_and_options(variant, quantity, options=[])
      desired_line_item = Spree::LineItem.new(variant_id: variant.id, quantity: quantity)
      desired_line_item.line_item_options = options.map{|e|   Spree::LineItemOption.new(variant_id: e[0].id, quantity: e[1]) }

      result = Spree::Stock::Quantifier.can_supply_order?(@order, desired_line_item)

      result[:errors].each {|err| self.errors.add(:base, err[:msg]) }
      result[:in_stock]
    end

    def add_quantity_for_each_option(variant, option_ids)
      # The option_ids will be a hash for the new dynamic kits 
      # otherwise an array for the old type kits
      # e.g. (dynamic kit options )  options = {
      #   "39" => [ "321" ],
      #   "40" => [ "205" ],
      #   part_id => [ selected_variant1, selected_variant2 ]
      # }
      #
      # ( static kit options )  options = [ 1,2,3 ]
      if variant.assembly_definition
        Spree::OrderPopulator.parse_options(variant, option_ids)
      else
        options = Spree::Variant.find(option_ids)
        options.map do |o|
          [o, part_quantity(variant,o)]
        end
      end
    end

    def part_quantity(variant, option)
      variant.product.optional_parts_for_display.detect{|e| e.id == option.id}.count_part
    end

  end
end
