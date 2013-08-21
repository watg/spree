module Spree
  class OptionValue < ActiveRecord::Base
    belongs_to :option_type, touch: true
    acts_as_list scope: :option_type
    has_and_belongs_to_many :variants, join_table: 'spree_option_values_variants', class_name: "Spree::Variant"

    validates :name, :presentation, presence: true

    attr_accessible :name, :presentation

    # This invalidates the variants cache
    after_save { self.delay.touch_variants }

    private

    def touch_variants
      self.variants.each { |v| v.touch }
    end
    
  end
end
