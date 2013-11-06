module Spree
  class ProductGroupTarget < ActiveRecord::Base
    belongs_to :product
    belongs_to :target
  end
end
