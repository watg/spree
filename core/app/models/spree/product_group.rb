module Spree
  class ProductGroup < ActiveRecord::Base
    attr_accessible :name, :description, :title, :permalink
    validates :name, uniqueness: true
    validates :name, presence: true
    validates :permalink, uniqueness: true
    
    has_many :products

    before_save :set_permalink

    def ready_made_products
      products.where("product_type is not 'kit'").displayable_variants
    end

    def kit_products
      products.where(product_type: :kit)
    end

    private
    def set_permalink
      if self.permalink.blank? && self.name
        self.permalink = '/'+ name.downcase.split(' ').map{|e| (e.blank? ? nil : e) }.compact.join('-')
      end
    end
  end
end
