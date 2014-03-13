class Spree::AssemblyDefinition < ActiveRecord::Base
  belongs_to :variant, class_name: "Spree::Variant"

  has_many :assembly_definition_parts,  -> { order(:position) }, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionPart' 
  alias_method :parts, :assembly_definition_parts

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"

end
