module Spree
  class ProductGroup < ActiveRecord::Base
    has_many :products
    
    validates :name, uniqueness: true

    # def next_variant_in_stock
    #   Spree::Variant.
    #     in_stock.
    #     includes(:product).
    #     joins('LEFT OUTER JOIN spree_product_groups ON spree_product_groups.id = spree_products.product_group_id').
    #     where("spree_product_groups.id = ? AND spree_products.individual_sale = ? AND spree_variants.is_master = ?", self, true, false).
    #     references(:product).
    #     first
    # end
  end
end
