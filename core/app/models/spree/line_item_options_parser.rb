module Spree
  class LineItemOptionsParser
    attr_accessor :currency

    def initialize(currency)
      @currency = currency
    end

    def personalisations(params)
      parse_personalisations(params)
    end

    def static_kit_optional_parts(variant, params)
      parts = []
      if params && params.any?
        options = Spree::Variant.find(params)
        options.each do |o|
          parts << Spree::LineItemPart.new(
            product_part_id: nil,
            variant_id: o.id,
            quantity:   part_quantity(variant, o),
            optional:   true,
            price:      part_price_amount(o),
            currency:   currency
          )
        end
      end
      parts
    end

    def static_kit_required_parts(variant)
      variant.required_parts_for_display.map do |r|
        Spree::LineItemPart.new(
          variant_id:                  r.id,
          quantity:                    r.count_part,
          optional:                    false,
          price:                       part_price_amount(r),
          currency:                    currency
        )
      end
    end

    def dynamic_kit_parts(variant, params)
      return [] if variant.product.parts.empty? || params.nil?

      parts = []
      params.each do |part_id, selected_part_variant_id|
        next if selected_part_variant_id == Spree::ProductPart::NO_THANKS

        product_part = valid_part(variant, part_id.to_i)
        selected_part_variant = valid_selected_part_variant(product_part, selected_part_variant_id.to_i)

        if selected_part_variant.required_parts_for_display.any?

          parent = Spree::LineItemPart.new(
            product_part_id: product_part.id,
            variant_id:                  selected_part_variant.id,
            quantity:                    product_part.count,
            optional:                    product_part.optional,
            price:                       part_price_amount(selected_part_variant),
            currency:                    currency
          )
          parts << parent

          selected_part_variant.required_parts_for_display.each do |sub_part|
            child = Spree::LineItemPart.new(
              product_part_id: product_part.id,
              variant_id:                  sub_part.id,
              quantity:                    sub_part.count_part * product_part.count,
              optional:                    false,
              price:                       part_price_amount(sub_part),
              currency:                    currency,
              parent_part:                 parent
            )

            parts << child
          end
        else
          parts << Spree::LineItemPart.new(
            product_part_id: product_part.id,
            variant_id:                  selected_part_variant.id,
            quantity:                    product_part.count,
            optional:                    product_part.optional,
            price:                       part_price_amount(selected_part_variant),
            currency:                    currency
          )
        end
      end

      parts
    end

    # parts => product_part.id => variant.id
    def missing_parts(variant, parts)
      product_part_ids = variant.product.product_parts.map(&:id)
      variant_ids = variant.product.product_part_variants.map(&:variant_id)

      parts.reject do |product_part_id, variant_id|
        part_ok = product_part_ids.include?(product_part_id.to_i)
        variant_not_required = (variant_id == Spree::ProductPart::NO_THANKS)

        if variant_not_required
          part_ok
        else
          variant_ok = variant_ids.include?(variant_id.to_i)
          part_ok && variant_ok
        end
      end
    end

    private

    def part_price_amount(part)
      price = part.price_part_in(currency).amount
      price ||= part.product.master.price_part_in(currency).amount
      price ||= part.price_normal_in(currency).amount
      price ||= part.product.master.price_normal_in(currency).amount
      price
    end

    def valid_part(variant, part_id)
      variant.product.product_parts.detect{ |p| p.id == part_id }
    end

    def valid_selected_part_variant(product_part, selected_part_variant_id)
      boolean = product_part.product_part_variants.detect do |v|
        v.variant_id == selected_part_variant_id
      end
      if boolean
        Spree::Variant.find(selected_part_variant_id)
      else
        nil
      end
    end

    def part_quantity(variant, option)
      variant.product.optional_parts_for_display.detect{ |e| e.id == option.id }.count_part
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
    # TODO: delete this
    def parse_personalisations(params)
      return [] unless params[:enabled_pp_ids]
      params[:enabled_pp_ids].map do |pp_id|
        pp_params = params[:pp_ids][pp_id]
        pp = Spree::Personalisation.find pp_id
        safe_params = pp.validate(pp_params)

        Spree::LineItemPersonalisation.new(
          personalisation_id: pp_id,
          amount: pp.prices[currency] || BigDecimal.new(0),
          data: safe_params
        )
      end
    end
  end
end
