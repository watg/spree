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
    find_selected_variants_out_of_stock {|part_id| find_variants_out_of_stock_per(part_id) }
  end

  def selected_variants_out_of_stock_option_values
    find_selected_variants_out_of_stock {|part_id| find_option_values_out_of_stock_per(part_id) }
  end

  private
  def find_selected_variants_out_of_stock
    Spree::AssemblyDefinitionPart.
      joins( assembly_definition_variants: [ variant: [:stock_items] ]).
      where("spree_assembly_definition_parts.count > spree_stock_items.count_on_hand").
      where("spree_assembly_definition_parts.assembly_definition_id = ?", self.id).
      reduce({}) {|hsh, part|
         hsh[part.id] = yield(part.id)
         hsh}
  end
  
  def find_variants_out_of_stock_per(assembly_definition_part_id)
    Spree::AssemblyDefinitionVariant.
      joins(:assembly_definition_part, variant: [:stock_items]).
      where("spree_stock_items.count_on_hand < spree_assembly_definition_parts.count").
      where(assembly_definition_part_id: assembly_definition_part_id).
      map(&:variant_id)
  end

  def find_option_values_out_of_stock_per(assembly_definition_part_id)
    Spree::AssemblyDefinitionVariant.
      joins(:assembly_definition_part, variant: [:stock_items]).
      where("spree_stock_items.count_on_hand < spree_assembly_definition_parts.count").
      where(assembly_definition_part_id: assembly_definition_part_id).
      map do |adv|
        v = adv.variant
        v.option_values.pluck(:id) if v
      end.compact
  end

  def set_assembly_product 
    self.assembly_product = self.variant.product
  end

end

