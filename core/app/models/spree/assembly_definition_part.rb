module Spree
  class AssemblyDefinitionPart < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :assembly_definition, class_name: "Spree::AssemblyDefinition", foreign_key: "assembly_definition_id"
    belongs_to :part_product, class_name: "Spree::Product", foreign_key: "product_id"
    belongs_to :assembly_product, class_name: "Spree::Product", foreign_key: "assembly_product_id", touch: true
    belongs_to :displayable_option_type, class_name: "Spree::OptionType", foreign_key: "displayable_option_type_id"

    has_many :assembly_definition_variants, dependent: :delete_all, class_name: 'Spree::AssemblyDefinitionVariant' 

    has_many :variants, through: :assembly_definition_variants
    alias_method :selected_variants, :variants

    has_many :option_values, -> { reorder(:position).uniq }, through: :variants

    accepts_nested_attributes_for :variants

    NO_THANKS = 'no_thanks'

    class << self
      def required
        where(optional: false)
      end
    end

    def required?
      !optional?
    end

    def displayable_option_values
      return [] unless displayable_option_type
      self.option_values.where(option_type: displayable_option_type )
    end

    def required_assembly_definition_variants
      assembly_definition_variants
    end
  end
end
