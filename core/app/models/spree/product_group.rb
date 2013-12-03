module Spree
  class ProductGroup < ActiveRecord::Base
    has_many :products
    
    validates :name, uniqueness: true
    has_and_belongs_to_many :product_pages, join_table: :spree_product_groups_product_pages

  end
end
