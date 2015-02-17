module Spree
  class AssemblyDefinitionPresenter < BasePresenter
    presents :assembly_definition

    def images
      @images ||= assembly_definition.images.with_target(target)
    end

    def displayable_suppliers
      part = assembly_definition.main_part || assembly_definition.parts.first
      variant = part.variants.first if part
      variant ? variant.suppliers.displayable : []
    end

  end
end


