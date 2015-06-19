class Spree::AssemblyDefinitionVariant < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant", foreign_key: "variant_id"
  belongs_to :assembly_definition_part, touch: true, class_name: "Spree::AssemblyDefinitionPart", foreign_key: "assembly_definition_part_id"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id"

  validates_presence_of :variant_id, :assembly_definition_part_id

  before_create :set_assembly_product

  # Return variant, even if deleted
  # Fixes admin errors on assembly definition.
  def variant
    Spree::Variant.unscoped { super }
  end

  private

  def set_assembly_product
    if assembly_definition_part.assembly_definition
      self.assembly_product = assembly_definition_part.assembly_definition.variant.product
    end
  end
end
