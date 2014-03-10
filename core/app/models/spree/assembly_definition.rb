class Spree::AssemblyDefinition < ActiveRecord::Base
  belongs_to :assembly, class_name: "Spree::Product", foreign_key: "assembly_id"
  belongs_to :part, class_name: "Spree::Product", foreign_key: "part_id"

  has_many :assembly_definition_variants, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionVariant' 
  has_many :variants, through: :assembly_definition_variants
  has_many :option_values, -> { uniq }, through: :variants

  accepts_nested_attributes_for :variants 

  delegate_belongs_to :part, :name

  def variant_options_tree_for(current_currency)
    variants.in_stock.options_tree_for(nil, current_currency)
  end

  def option_values_in_stock
    option_values.where('spree_variants.in_stock_cache =?', true)
  end

  def grouped_option_values_in_stock
   ordered_option_values = option_values_in_stock.includes(:option_type).joins(:option_type).
     reorder( "spree_option_types.position", "spree_option_values.position" )

   # This is instead of a group_by(&:option_type) as it would achieve the same result
   # but it a lot less friendly to caching
   group = ActiveSupport::OrderedHash.new 
   ots = {}
   ordered_option_values.each do |ov|
     ots[ov.option_type_id] ||= ov.option_type 
     group[ots[ov.option_type_id]] ||= []
     group[ots[ov.option_type_id]] << ov 
   end
   group
  end

end
