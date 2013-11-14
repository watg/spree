module Spree
  class ProductPageVariant < ActiveRecord::Base
    belongs_to :product_page
    belongs_to :variant
  end
end
