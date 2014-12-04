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



    #### Targetted accessors ###

    def variants
      @variants ||= product.variants_for(target)
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

    def grouped_option_values
      @grouped_option_values ||= product.grouped_option_values_for(target)
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


    ### Presenters ###

    def product_options_presenter
      @product_options_presenter ||= Spree::ProductOptionsPresenter.new(product, template, context)
    end

    def assembly_definition_presenter
      @assembly_definition_presenter ||= begin
        AssemblyDefinitionPresenter.new(assembly_definition, template, context) if assembly_definition
      end
    end

    def assembly_definition_part_presenters
      assembly_definition_parts.map do |part|
        presenter = AssemblyDefinitionPartPresenter.new(part, template, context)
        yield presenter if block_given?
        presenter
      end
    end

    def suppliers_variant_presenter
      if assembly_definition
        part = assembly_definition.main_part || assembly_definition_parts.first
        build_variant_presenter(part.variants.first)
      else
        first_variant_or_master_presenter
      end
    end

    def first_variant_or_master_presenter
      @first_variant_or_master_presenter ||= begin
        variant = product.variants.in_stock.first || product.master
        build_variant_presenter(variant)
      end
    end

    ### end of presenters ###

    private

    def build_variant_presenter(variant)
      VariantPresenter.new(variant, template, context)
    end

  end
end
