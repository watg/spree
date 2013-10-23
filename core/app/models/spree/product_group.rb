module Spree
  class ProductGroup < ActiveRecord::Base
    validates :name, :presence => true
    
    has_many :products
  end
end
