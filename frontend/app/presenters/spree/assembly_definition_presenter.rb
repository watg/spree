module Spree
  class AssemblyDefinitionPresenter < BasePresenter
    presents :assembly_definition

    def images
      @images ||= assembly_definition.images.with_target(target)
    end

  end
end


