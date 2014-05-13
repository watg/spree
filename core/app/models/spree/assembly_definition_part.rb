class Spree::AssemblyDefinitionPart < ActiveRecord::Base
  acts_as_paranoid

  acts_as_list scope: [:assembly_definition_id, :deleted_at]

  belongs_to :assembly_definition, class_name: "Spree::AssemblyDefinition", foreign_key: "assembly_definition_id"
  belongs_to :product, class_name: "Spree::Product", foreign_key: "product_id"
  belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id", touch: true
  belongs_to :displayable_option_type, class_name: "Spree::OptionType", foreign_key: "displayable_option_type_id"

  has_many :assembly_definition_variants, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionVariant' 
  
  has_many :variants, through: :assembly_definition_variants
  alias_method :selected_variants, :variants

  has_many :option_values, -> { reorder('').uniq }, through: :variants

  accepts_nested_attributes_for :variants 

  before_create :set_assembly_product

  validates_presence_of :displayable_option_type

  def variant_options_tree_for(current_currency)
    variants.options_tree_for(nil, current_currency)
  end

  def displayable_option_values
    self.option_values.where(option_type: displayable_option_type )
  end

  private
  def set_assembly_product
    self.assembly_product = self.assembly_definition.variant.product
  end

end
