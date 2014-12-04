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

    def displayable_option_values
      @displayable_option_values ||= assembly_definition_part.displayable_option_values
    end

    def displayable_option_type
      @displayable_option_type ||= assembly_definition_part.displayable_option_type
    end


    ### start of presenters ###

    def product_options_presenter
      @product_options_presenter ||= Spree::ProductOptionsPresenter.new(assembly_definition_part, template, context)
    end

    ### end of presenters ###
    private


  end
end


