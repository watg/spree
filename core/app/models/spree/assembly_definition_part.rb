class Spree::AssemblyDefinitionPart < ActiveRecord::Base
  acts_as_paranoid

  acts_as_list scope: [:assembly_definition_id, :deleted_at]

  belongs_to :assembly_definition, class_name: "Spree::AssemblyDefinition", foreign_key: "assembly_definition_id"
  belongs_to :product, class_name: "Spree::Product", foreign_key: "product_id"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id", touch: true

  has_many :assembly_definition_variants, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionVariant' 
  
  has_many :variants, through: :assembly_definition_variants
  alias_method :selected_variants, :variants

  has_many :option_values, -> { reorder('').uniq }, through: :variants

  accepts_nested_attributes_for :variants 

  before_create :set_assembly_product

  def variant_options_tree_for(current_currency)
    variants.options_tree_for(nil, current_currency)
  end

  def grouped_option_values()
    selector = option_values.includes(:option_type).joins(:option_type)

    ordered_option_values = selector.reorder( "spree_option_types.position", "spree_option_values.position" )

    # This is instead of a group_by(&:option_type) as it would achieve the same result
    # but it a lot less friendly to caching
    group = ActiveSupport::OrderedHash.new 
    ots = {}
    ordered_option_values.each do |ov|
      ots[ov.option_type_id] ||= ov.option_type 
      group[ots[ov.option_type_id]] ||= []
      group[ots[ov.option_type_id]] << ov 
    end
    # We do not want to keep any option_types that have 1 or less values
    #group.keep_if {|k,v| v.size >1 }
    group
  end

  private
  def set_assembly_product 
    self.assembly_product = self.assembly_definition.variant.product
  end


end
