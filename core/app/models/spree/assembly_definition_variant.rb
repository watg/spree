module Spree
  class AssemblyDefinitionVariant < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :variant, class_name: "Spree::Variant", foreign_key: "variant_id"
    belongs_to :assembly_definition, class_name: "Spree::AssemblyDefinition", foreign_key: "assembly_definition_id"

    validates_presence_of :variant_id, :assembly_definition_id
  end
end
