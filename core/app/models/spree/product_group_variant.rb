module Spree
  class ProductGroupVariant < ActiveRecord::Base
    belongs_to :product_group
    belongs_to :variant
  end
end
