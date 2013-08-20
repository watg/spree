module Spree
  class ProductOptionType < ActiveRecord::Base
    belongs_to :product, class_name: 'Spree::Product', touch: true
    belongs_to :option_type, class_name: 'Spree::OptionType', touch: true
    acts_as_list scope: :product
    attr_accessible :product_id, :option_type_id, :visible
  end
end
