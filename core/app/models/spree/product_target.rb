module Spree
  class ProductTarget < ActiveRecord::Base
    belongs_to :product
    belongs_to :target
  end
end
