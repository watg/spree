class Spree::AssemblyDefinitionVariant < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant", foreign_key: "variant_id"
  belongs_to :assembly_definition_part, touch: true, class_name: "Spree::AssemblyDefinitionPart", foreign_key: "assembly_definition_part_id"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id"#, touch: true

  validates_presence_of :variant_id, :assembly_definition_part_id

  before_create :set_assembly_product

  def part_prices
    variant.part_prices
  end

  private

  def set_assembly_product
    self.assembly_product = self.assembly_definition_part.assembly_definition.variant.product
  end

end
