module Spree
  class OrderPopulator
    attr_accessor :order, :currency, :options_parser
    attr_reader :errors

    def initialize(order, _currency)
      @order = order
      @currency = order.currency
      @errors = ActiveModel::Errors.new(self)
      @options_parser = Spree::LineItemOptionsParser.new(currency)
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
    #  :target_id => 2,
    #  :product_page_tab_id => 1,
    #  :product_page_id => 2,
    #  :suite_id => 2,
    #  :suite_tab_id => 1,
    #  :options => [56, 34] # array of variant_ids
    #  ....
    def populate(params)
      # Only interested in the first variant
      if variants = params.delete(:variants)
        parse_variants_style_params(variants, params)

      elsif products = params.delete(:products)
        parse_products_style_params(products, params)

      end

      valid?
    end

    def attempt_cart_add(variant, quantity, options)

      if quantity > 0

        line_item = order.contents.add(variant, quantity, options)

        if line_item.errors.any?
          errors.add(:base, line_item.errors.messages.values.join(" "))
          return false
        end

      end
    end

    def valid?
      errors.empty?
    end

    private

    def parse_variants_style_params(variants, params)

      variant_id, quantity = variants.first
      quantity = quantity.to_i

      if is_quantity_reasonable?(quantity)
        variant = Spree::Variant.includes(assembly_definition: [assembly_definition_parts: [:assembly_definition_variants]]).find(variant_id)

        if parts = params.delete(:parts)

          missing_parts = options_parser.missing_parts(variant, parts)

          if missing_parts.any?

            missing_parts_as_params = missing_parts.inject({}) do |hash, (part,variant)| 
              hash[part.id] = variant.id
              hash
            end

            notifier_params = params.merge(
              order_id: order.id, missing_parts_and_variants: missing_parts_as_params)

            Helpers::AirbrakeNotifier.delay.notify("Some required parts are missing", notifier_params)
            errors.add(:base, "Some required parts are missing")
            return false
          end

        end

        params[:parts] = options_parser.dynamic_kit_parts(variant, parts)

        attempt_cart_add(variant, quantity, params || {})
      end

    end

    def parse_products_style_params(products, params)

      quantity = params.delete(:quantity).to_i
      if is_quantity_reasonable?(quantity)
        # products"=>{"401"=>"1997", "options"=>["325"], "personalisations"=>{}}
        # We need to delete the keys(parts, personalisations from the hash first before we can call
        # first to get the variant and quantity, this is Fing horrible and needs refactoring
        optional_parts_params = products.delete(:options)

        personalisation_params = {
          enabled_pp_ids: products.delete(:enabled_pp_ids) || [],
          pp_ids:         products.delete(:pp_ids) || {}
        }

        _product_id, variant_id = products.first
        variant = Spree::Variant.find(variant_id)

        params[:parts] = options_parser.static_kit_required_parts(variant)
        params[:parts] += options_parser.static_kit_optional_parts(variant, optional_parts_params)

        params[:personalisations] = options_parser.personalisations(personalisation_params)

        attempt_cart_add(variant, quantity || 1, params || {})
      end

    end

    def is_quantity_reasonable?(quantity)

      # 2,147,483,647 is crazy.
      # See issue #2695.
      if quantity > 2_147_483_647
        errors.add(:base, Spree.t(:please_enter_reasonable_quantity, :scope => :order_populator))
        false
      else
        true
      end
    end


    def build_personalisations(params)
      value = {
        enabled_pp_ids: params[:products].delete(:enabled_pp_ids) || [],
        pp_ids:         params[:products].delete(:pp_ids) || {}
      }
      options_parser.personalisations(value)
    end

  end
end
