module Spree
  class ProductGroup < ActiveRecord::Base
    has_many :products
    
    validates :name, uniqueness: true
    has_and_belongs_to_many :product_pages, join_table: :spree_product_groups_product_pages

    def next_variant_in_stock
      Spree::Variant.
        includes(:stock_items, :product).
        joins('LEFT OUTER JOIN spree_product_groups ON spree_product_groups.id = spree_products.product_group_id').
        where("spree_product_groups.id = ? AND spree_stock_items.count_on_hand > 0 AND spree_stock_items.count_on_hand < 500 AND spree_products.individual_sale = ?", self, true).
        where("spree_variants.is_master = ?", false).
        references(:stock_items, :product).
        first
    end

  end
end
