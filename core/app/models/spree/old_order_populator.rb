module Spree
  class OldOrderPopulator
    attr_accessor :order, :currency, :options_parser
    attr_reader :errors, :item

    Item = Struct.new(:variant, :quantity)

    def initialize(order, _currency)
      @order = order
      @currency = order.currency
      @errors = ActiveModel::Errors.new(self)
      @options_parser = Spree::LineItemOptionsParser.new(currency)
      @item = nil
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
        else
          @item = Item.new(variant, quantity)
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

        variant = Spree::Variant.includes(product_part_variants: :product_parts)
          .find(variant_id)

        parts = params.delete(:parts)
        missing_parts = options_parser.missing_parts(variant, parts)

        if missing_parts.empty?
          params[:parts] = options_parser.dynamic_kit_parts(variant, parts)
          attempt_cart_add(variant, quantity, params || {})
        else
          missing_parts_hash = missing_parts.inject({}) do |hash, missing_part|
            (missing_part_id, missing_variant_id) = missing_part
            hash[missing_part_id] = missing_variant_id
            hash
          end

          notifier_params = params.merge(
            order_id: order.id,
            parts: parts,
            missing_parts_and_variants: missing_parts_hash
          )

          Helpers::AirbrakeNotifier.notify("Some required parts are missing", notifier_params)
          errors.add(:base, "Some required parts are missing")
          return false
        end

      else
        add_reasonable_quantity_error
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

      else
        add_reasonable_quantity_error
      end

    end

    def is_quantity_reasonable?(quantity)
      # 2,147,483,647 is crazy.
      # See issue #2695.
      if quantity > 2_147_483_647
        false
      else
        true
      end
    end

    def add_reasonable_quantity_error
      errors.add(:base, Spree.t(:please_enter_reasonable_quantity, :scope => :order_populator))
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
