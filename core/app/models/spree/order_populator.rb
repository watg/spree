module Spree
  class OrderPopulator
    attr_accessor :order, :currency
    attr_reader :errors

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
    # +:products => { product_id => variant_id, product_id => variant_id }, :quantity => quantity+
    def populate(from_hash)
      # product_assembly
      options = extract_kit_options(from_hash)
      personalisations = extract_personalisations(from_hash)
      target_id = from_hash[:products].delete(:target_id) if from_hash[:products]

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
      (value || [])
    end

    # This will return an array of hashes incase we have multiple
    # personalisations
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
      options = Spree::Variant.find(option_ids)
      options_with_qty = add_quantity_for_each_option(variant, options)

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

    def check_stock_levels(variant, quantity)
      display_name = %Q{#{variant.name}}
      display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?

      if Stock::Quantifier.new(variant).can_supply? quantity
        true
      else
        errors.add(:base, Spree.t(:out_of_stock, :scope => :order_populator, :item => display_name.inspect))
        return false
      end
    end


    def check_stock_levels_for_variant_and_options(variant, quantity, options=[])
      stock_check = [check_stock_levels(variant, quantity)]

      # Check stock for optional parts
      options_check = options.map do |e|
        check_stock_levels(e[0], e[1])
      end

      stock_check += options_check if options_check

      are_all_parts_in_stock?(stock_check)
    end

    def add_quantity_for_each_option(variant, options)
      options.map do |o|
        [o, part_quantity(variant,o)]
      end
    end

    def part_quantity(variant, option)
      variant.product.optional_parts_for_display.detect{|e| e.id == option.id}.count_part
    end

    def are_all_parts_in_stock?(check_list)
      check_list.inject(true) { |result, bool| bool && result}
    end
  end
end
