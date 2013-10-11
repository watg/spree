module Spree
  class ProductGroup < ActiveRecord::Base
    #attr_accessible :name, :description
    validates :name, :presence => true
    
    has_many :products
  end
end
