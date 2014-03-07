class Spree::AssemblyDefinition < ActiveRecord::Base
  belongs_to :assembly, class_name: "Spree::Product", foreign_key: "assembly_id"
  belongs_to :part, class_name: "Spree::Product", foreign_key: "part_id"

  has_many :assembly_definition_variants, dependent: :delete_all
  has_many :variants, through: :assembly_definition_variants
  has_many :option_values, through: :variants

  accepts_nested_attributes_for :variants 

  delegate_belongs_to :part, :name

  def variant_options_tree_for(target, current_currency)
    variants.in_stock.options_tree_for(target, current_currency)
  end

end
