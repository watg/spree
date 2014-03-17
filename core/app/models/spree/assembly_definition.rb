class Spree::AssemblyDefinition < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id", touch: true

  has_many :assembly_definition_parts,  -> { order(:position) }, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionPart' 
  alias_method :parts, :assembly_definition_parts

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::AssemblyDefinitionImage"
  accepts_nested_attributes_for :images

  def selected_variants_out_of_stock
    Spree::AssemblyDefinitionPart.
      joins( assembly_definition_variants: [ variant: [:stock_items] ]).
      where("spree_assembly_definition_parts.count > spree_stock_items.count_on_hand").
      where("spree_assembly_definition_parts.assembly_definition_id = ?", self.id).
      reduce({}) {|hsh, part|
      hsh[part.id] = find_variants_out_of_stock_per(part.id)
      hsh}
  end

  private
  
  def find_variants_out_of_stock_per(assembly_definition_part_id)
    Spree::AssemblyDefinitionVariant.
      joins(:assembly_definition_part, variant: [:stock_items]).
      where("spree_stock_items.count_on_hand < spree_assembly_definition_parts.count").
      where(assembly_definition_part_id: assembly_definition_part_id).
      map(&:variant_id)
  end
end

