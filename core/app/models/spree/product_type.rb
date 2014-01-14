module Spree
  class ProductType < ActiveRecord::Base
    validates :name, uniqueness: true
  end
end
