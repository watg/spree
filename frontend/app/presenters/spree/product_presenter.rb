module Spree
  class ProductPresenter < BasePresenter
    presents :product

    delegate :id, :name, :slug, :out_of_stock_override?, to: :product

    ### Memoized accessors ###

    def has_variants?
      @has_variant ||= product.has_variants?
    end

    def master
      @mater ||= product.master
    end

    def price
      @price ||= product.price_normal_in(currency)
    end

    def personalisations
      @personalisations ||= product.personalisations
    end

    def personalisation_images
      @personalisation_images ||= product.personalisation_images
    end

    def optional_parts_for_display
      @optional_parts_for_display ||= product.optional_parts_for_display
    end

    #### option value methods ####

    def variant_tree
      variant_options.tree
    end

    def option_type_order
      variant_options.option_type_order
    end

    def grouped_option_values_in_stock
      variant_options.grouped_option_values_in_stock
    end

    def option_types_and_values
      variant_options.option_types_and_values_for(first_variant_or_master)
    end

    def variant_option_values
      variant_options.variant_option_values
    end

    #### Targetted accessors ###

    def variants
      @variants ||= product.variants_for(target).in_stock
    end

    def clean_description
      product.clean_description_for(target)
    end

    def images
      @images ||= product.images_for(target)
    end

    def variant_images
      @variant_images ||= product.variant_images_for(target)
    end

    def image_style
      is_mobile? ? :small : :product
    end


    ### Assembly definition accessors ###
    def assembly_definition
      @asem_def ||= product.assembly_definition
    end

    def assembly_definition_parts
      @assembly_definition_parts ||= assembly_definition.parts
    end


    ### Regular methods ##

    def part_price_in_pence(part)
      method = (part.is_master ? :price_normal_in : :price_part_in)
      price = part.send(method, currency).price
      ( price * 100 * part_quantity(part) ).to_i
    end

    def part_quantity(part)
      @part_quantity ||= {}
      return @part_quantity[part] if @part_quantity[part]
      @part_quantity[part] = part.try(:count_part) || 1
      @part_quantity[part]
    end

    def first_variant_or_master
      @first_variant_or_master ||= begin
        variants.first || product.master
      end
    end

    ### Presenters ###

    def assembly_definition_presenter
      @assembly_definition_presenter ||= begin
        AssemblyDefinitionPresenter.new(assembly_definition, template, context) if assembly_definition
      end
    end

    private

    def build_variant_presenter(variant)
      VariantPresenter.new(variant, template, context)
    end

    def variant_options
      @variant_options ||= Spree::VariantOptions.new(variants, currency)
    end

  end
end
