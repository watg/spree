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
      if params and params.any?
        options = Spree::Variant.find(params)
        options.each do |o|
          parts << Spree::LineItemPart.new(
            assembly_definition_part_id: nil,
            variant_id: o.id,
            quantity:   part_quantity(variant,o),
            optional:   true,
            price:      o.price_part_in(currency).amount || o.price_normal_in(currency).amount,
            currency:   currency,
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
          price:                       r.price_part_in(currency).amount || r.price_normal_in(currency).amount,
          currency:                    currency
        )
      end
    end

    def dynamic_kit_parts(variant, params)
      return [] if !variant.assembly_definition or params.nil?

      parts = []
      params.each do |part_id, selected_part_variant_id|
        if assembly_definition_part = valid_part( variant, part_id.to_i )

          if selected_part_variant = valid_selected_part_variant( assembly_definition_part, selected_part_variant_id.to_i )

            main_part_id = assembly_definition_part.assembly_definition.main_part_id

            if selected_part_variant.required_parts_for_display.any?
              # Adding the container. It may be optional.
              #
              parent = Spree::LineItemPart.new(
                assembly_definition_part_id: assembly_definition_part.id,
                variant_id:                  selected_part_variant.id,
                quantity:                    assembly_definition_part.count,
                optional:                    assembly_definition_part.optional,
                price:                       selected_part_variant.price_part_in(currency).amount,
                currency:                    currency,
                assembled:                   assembly_definition_part.assembled,
                container:                   true,
                main_part:                   (assembly_definition_part.id == main_part_id)
              )
              parts << parent

              # Adding the parts of the container. They are always required.
              selected_part_variant.required_parts_for_display.each do |sub_part|
                child = Spree::LineItemPart.new(
                  assembly_definition_part_id: assembly_definition_part.id,
                  variant_id:                  sub_part.id,
                  quantity:                    sub_part.count_part * assembly_definition_part.count,
                  optional:                    false,
                  price:                       sub_part.price_part_in(currency).amount,
                  currency:                    currency,
                  assembled:                   assembly_definition_part.assembled,
                  parent_part:                 parent,
                )

                parts << child
              end
            else
              parts << Spree::LineItemPart.new(
                assembly_definition_part_id: assembly_definition_part.id,
                variant_id:                  selected_part_variant.id,
                quantity:                    assembly_definition_part.count,
                optional:                    assembly_definition_part.optional,
                price:                       selected_part_variant.price_part_in(currency).amount,
                currency:                    currency,
                assembled:                   assembly_definition_part.assembled,
                main_part:                   (assembly_definition_part.id == main_part_id)
              )
            end
          end
        end
      end

      parts
    end

    def missing_required_parts(variant, parts)
      parts_id = parts.keys.map(&:to_i)
      variant.assembly_definition.parts.required.select {|part| !parts_id.include?(part.id)}
    end

    private

    def valid_part( variant, part_id )
      variant.assembly_definition.parts.detect{|p| p.id == part_id}
    end

    def valid_selected_part_variant( assembly_definition_part, selected_part_variant_id )
      boolean = assembly_definition_part.assembly_definition_variants.detect do |v|
        v.variant_id == selected_part_variant_id
      end
      if boolean
        Spree::Variant.find(selected_part_variant_id)
      else
        nil
      end
    end

    def part_quantity(variant, option)
      variant.product.optional_parts_for_display.detect{|e| e.id == option.id}.count_part
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
    def parse_personalisations(params)
      return [] unless params[:enabled_pp_ids]
      params[:enabled_pp_ids].map do |pp_id|
        pp_params = params[:pp_ids][pp_id]
        pp = Spree::Personalisation.find pp_id
        safe_params = pp.validate( pp_params )

        Spree::LineItemPersonalisation.new(
          personalisation_id: pp_id,
          amount: pp.prices[currency] || BigDecimal.new(0),
          data: safe_params,
        )
      end
    end

  end

end

