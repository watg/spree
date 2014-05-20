class Spree::AssemblyDefinition < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id", touch: true

  has_many :assembly_definition_parts,  -> { order(:position) }, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionPart' 
  alias_method :parts, :assembly_definition_parts

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::AssemblyDefinitionImage"

  accepts_nested_attributes_for :images
  accepts_nested_attributes_for :assembly_definition_parts

  before_create :set_assembly_product

  def selected_variants_out_of_stock
    Spree::AssemblyDefinitionVariant.joins(:assembly_definition_part, variant: [:stock_items]).
      where("spree_stock_items.count_on_hand < spree_assembly_definition_parts.count").
      where("spree_assembly_definition_parts.assembly_definition_id = ?", self.id).inject({}) do |hash,adv| 
        hash[adv.assembly_definition_part_id] ||= []
        hash[adv.assembly_definition_part_id] << adv.variant_id
        hash
      end
  end

  def selected_variants_out_of_stock_option_values
    Spree::AssemblyDefinitionVariant.joins(:assembly_definition_part, variant: [:stock_items]).
      includes(variant: [:option_values]).
      where("spree_stock_items.count_on_hand < spree_assembly_definition_parts.count").
      where("spree_assembly_definition_parts.assembly_definition_id = ?", self.id).inject({}) do |hash,adv| 
        hash[adv.assembly_definition_part_id] ||= []
        hash[adv.assembly_definition_part_id] << adv.variant.option_values.map(&:id)
        hash
      end
  end

  private

  def set_assembly_product 
    self.assembly_product = self.variant.product
  end

end
