module Spree
  class AssemblyDefinitionPartPresenter < BasePresenter
    presents :assembly_definition_part
    delegate :id, :optional?, :count, :presentation, to: :assembly_definition_part

    def variants
      @variants ||= assembly_definition_part.variants
    end

    def first_variant
      variants.first
    end

    def product_name
      @product_name ||= assembly_definition_part.product.name
    end

    def displayable_option_type
      @displayable_option_type ||= assembly_definition_part.displayable_option_type
    end

    #### option value methods ####

    def variant_tree
      variant_options.simple_tree
    end

    def displayable_option_values
      @displayable_option_values ||= variant_options.option_values_in_stock
    end

    ###############################


    private

    def variant_options
      @variant_options ||= Spree::VariantOptions.new(variants, currency)
    end

  end
end


