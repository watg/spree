module Spree
  class ProductGroup < ActiveRecord::Base
    attr_accessible :name, :description
    validates :name, :presence => true
    
    has_many :products

    def ready_made_products
# 
      products.where("product_type is not 'kit'").displayable_variants
    end

    def kit_products
      products.where(product_type: :kit)
    end

    def permalink
      name.downcase.split(' ').map{|e| (e.blank? ? nil : e) }.compact.join('-')
    end
  end
end
