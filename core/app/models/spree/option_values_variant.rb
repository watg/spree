module Spree
  class OptionValuesVariant < ActiveRecord::Base
    belongs_to :option_value, class_name: 'Spree::OptionValue', inverse_of: :option_values_variants
    belongs_to :variant, class_name: 'Spree::Variant', inverse_of: :option_values_variants
  end
end

