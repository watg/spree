module Spree
  class ProductPart < ActiveRecord::Base
    acts_as_paranoid
    acts_as_list scope: [:product_id, :deleted_at]

    belongs_to :product, class_name: "Spree::Product", foreign_key: "product_id", touch: true
    belongs_to :part, class_name: "Spree::Product", foreign_key: "part_id"
    belongs_to :displayable_option_type, class_name: "Spree::OptionType", foreign_key: "displayable_option_type_id"

    has_many :product_part_variants,
             dependent: :delete_all,
             class_name: "Spree::ProductPartVariant"

    has_many :variants, through: :product_part_variants
    alias_method :selected_variants, :variants

    has_many :option_values, -> { reorder(:position).uniq }, through: :variants

    accepts_nested_attributes_for :variants

    NO_THANKS = "no_thanks"

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
      option_values.where(option_type: displayable_option_type)
    end
  end
end
