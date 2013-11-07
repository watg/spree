module Spree
  class ProductTarget < ActiveRecord::Base
    belongs_to :product
    belongs_to :target

    validates_presence_of :product_id, :target_id
  end
end
