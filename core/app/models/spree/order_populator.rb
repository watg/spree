module Spree
  class OrderPopulator
    attr_accessor :order, :currency
    attr_reader :errors

    class << self
      def have_all_required_parts(variant, parts)
        return [] unless variant.assembly_definition
        parts_id = parts.map(&:assembly_definition_part_id)
        variant.assembly_definition.parts.required.select {|part| !parts_id.include?(part.id)}
      end


      #  Dynamic kit params
      #      params = {
      #        "34" => [ "217" ],
      #        "35" => [ "4618" ],
      #        "36" => ["321" ]
      #      }
      #  Old style Kit params
      #  params = [ 123, 34, 1 ]
      def parse_options(variant, params, currency)
        parts = []
        return parts unless params

        if params.kind_of? Array
          parts = parse_options_for_old_kit(variant, params, currency)
          parts += add_required_parts(variant, currency)
        elsif variant.assembly_definition
          parts = parse_options_for_assembly(variant, params, currency)
        end

        parts
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
      def parse_personalisations(params, currency)
        return [] unless params[:enabled_pp_ids]
        params[:enabled_pp_ids].map do |pp_id|
          pp_params = params[:pp_ids][pp_id]
          pp = Spree::Personalisation.find pp_id
          safe_params = pp.validate( pp_params )
          # line_item_part_id = safe_params.delete(:line_item_part_id)
          OpenStruct.new(
            personalisation_id: pp_id,
            amount: pp.prices[currency],
            data: safe_params,
            # line_item_part_id: line_item_part_id
          )
        end
      end

      private

      def add_required_parts(variant, currency)
        variant.required_parts_for_display.map do |r|
          OpenStruct.new(
            assembly_definition_part_id: nil,
            variant_id:                  r.id,
            quantity:                    r.count_part,
            optional:                    false,
            price:                       r.price_part_in(currency).amount,
            currency:                    currency,
            main_part:                   false,
            container:                   false
          )
        end
      end

      def parse_options_for_assembly(variant, params, currency)
        parts = []

        params.each_with_index do |(part_id, selected_part_variant_id), index|
          if assembly_definition_part = valid_part( variant, part_id.to_i )

            if selected_part_variant = valid_selected_part_variant( assembly_definition_part, selected_part_variant_id.to_i )

              main_part_id = assembly_definition_part.assembly_definition.main_part_id

              if selected_part_variant.required_parts_for_display.any?
                # Adding the container. It may be optional.

                parts << OpenStruct.new(
                  assembly_definition_part_id: assembly_definition_part.id,
                  variant_id:                  selected_part_variant.id,
                  quantity:                    assembly_definition_part.count,
                  optional:                    assembly_definition_part.optional,
                  price:                       selected_part_variant.price_part_in(currency).amount,
                  currency:                    currency,
                  assembled:                   assembly_definition_part.assembled,
                  container:                   true,
                  id:                          index,
                  main_part:                   (assembly_definition_part.id == main_part_id)
                )

                # Adding the parts of the container. They are always required.
                selected_part_variant.required_parts_for_display.each do |sub_part|
                  parts << OpenStruct.new(
                    assembly_definition_part_id: assembly_definition_part.id,
                    variant_id:                  sub_part.id,
                    quantity:                    sub_part.count_part * assembly_definition_part.count,
                    optional:                    false,
                    container:                   false,
                    price:                       sub_part.price_part_in(currency).amount,
                    currency:                    currency,
                    assembled:                   assembly_definition_part.assembled,
                    parent_part_id:              index,
                    main_part:                   false
                  )
                end
              else
                parts << OpenStruct.new(
                  assembly_definition_part_id: assembly_definition_part.id,
                  variant_id:                  selected_part_variant.id,
                  quantity:                    assembly_definition_part.count,
                  optional:                    assembly_definition_part.optional,
                  price:                       selected_part_variant.price_part_in(currency).amount,
                  currency:                    currency,
                  assembled:                   assembly_definition_part.assembled,
                  container:                   false,
                  main_part:                   (assembly_definition_part.id == main_part_id)
                )
              end
            end
          end
        end

        parts
      end

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

      def parse_options_for_old_kit(variant, params, currency)
        parts = []
        if params.any?
          options = Spree::Variant.find(params)
          options.each do |o|
            parts << OpenStruct.new(
              assembly_definition_part_id: nil,
              variant_id: o.id,
              quantity:   part_quantity(variant,o),
              optional:   true,
              price:      o.price_part_in(currency).amount,
              currency:   currency,
              main_part:  false,
              container:  false
            )
          end
        end
        parts
      end

      def part_quantity(variant, option)
        variant.product.optional_parts_for_display.detect{|e| e.id == option.id}.count_part
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
    #  :target_id => 2,
    #  :product_page_tab_id => 1,
    #  :product_page_id => 2,
    #  :options => [56, 34] # array of variant_ids
    #  ....
    def populate(from_hash)

      product_page_id = from_hash[:product_page_id]
      product_page_tab_id = from_hash[:product_page_tab_id]

      options = extract_kit_options(from_hash)
      personalisations = extract_personalisations(from_hash)


      target_id = from_hash[:target_id]
      # Coearce the target_id to nil if it is blank, as this makes find_by( target_id: target_id )
      # behave as target_id is actually a integer in the DB, which is used later as part of the
      # variantuuid code
      target_id = nil if target_id.blank?


      from_hash[:products].each do |product_id,variant_id|
        attempt_cart_add(variant_id, from_hash[:quantity], options, personalisations, target_id,
                        product_page_tab_id, product_page_id)
      end if from_hash[:products]

      from_hash[:variants].each do |variant_id, quantity|
        attempt_cart_add(variant_id, quantity, options, personalisations, target_id,
                        product_page_tab_id, product_page_id)
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
      value = hash.delete(:parts).to_hash if hash[:parts]
      (value || [])
    end

    def extract_personalisations(hash)
      return {} unless hash[:products]
      {
        enabled_pp_ids: hash[:products].delete(:enabled_pp_ids) || [],
        pp_ids:         hash[:products].delete(:pp_ids) || {}
      }
    end

    # This has modifications for options and personalisations
    def attempt_cart_add(variant_id, quantity, option_params, personalisation_params, target_id,
                         product_page_tab_id, product_page_id)
      quantity = quantity.to_i
      # 2,147,483,647 is crazy.
      # See issue #2695.
      if quantity > 2_147_483_647
        errors.add(:base, Spree.t(:please_enter_reasonable_quantity, :scope => :order_populator))
        return false
      end

      variant = Spree::Variant.find variant_id

      parts = Spree::OrderPopulator.parse_options(variant, option_params, currency)

      missing_required_parts = Spree::OrderPopulator.have_all_required_parts(variant, parts)
      if missing_required_parts.any?
        errors.add(:base, "Some required parts are missing")
        return false
      end

      personalisations = Spree::OrderPopulator.parse_personalisations(personalisation_params, currency)

      if quantity > 0
        options = {
          shipment: nil,
          personalisations: personalisations,
          target_id: target_id,
          parts: parts,
          product_page_tab_id: product_page_tab_id,
          product_page_id: product_page_id
        }

        line_item = @order.contents.add(variant, quantity, currency, options)
        unless line_item.valid?
          errors.add(:base, line_item.errors.messages.values.join(" "))
          return false
        end
      end
    end

  end
end
