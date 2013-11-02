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

      from_hash[:products].each do |product_id,variant_id|
        attempt_cart_add(variant_id, from_hash[:quantity], options, personalisations)
      end if from_hash[:products]

      from_hash[:variants].each do |variant_id, quantity|
        attempt_cart_add(variant_id, quantity, options, personalisations )
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
      enabled_pp_ids = hash[:products].delete(:enabled_pp_ids) || []
      pp_ids = hash[:products].delete(:pp_ids) || {}
      enabled_pp_ids.map do |pp_id|
        params = pp_ids[pp_id]
        pp = Spree::Personalisation.find pp_id
        safe_params = pp.validate( params )
        {
          personalisation_id: pp_id, 
          prices: pp.prices,
          data: safe_params
        }
      end
    end

    # This has modifications for options and personalisations
    def attempt_cart_add(variant_id, quantity, option_ids=[], personalisations=[])
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
          line_item = @order.contents.add(variant, quantity, currency, shipment, options_with_qty, personalisations)
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

  end
end
