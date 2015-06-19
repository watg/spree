class Spree::AssemblyDefinition < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id"

  has_many :assembly_definition_parts,  -> { order(:position) }, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionPart'
  alias_method :parts, :assembly_definition_parts

  has_many :assembly_definition_variants, through: :assembly_definition_parts

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::AssemblyDefinitionImage"

  accepts_nested_attributes_for :images
  accepts_nested_attributes_for :assembly_definition_parts

  def images_for(target)
    images.with_target(target)
  end

end
