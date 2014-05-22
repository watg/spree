module Spree
  class ProductGroup < ActiveRecord::Base
    has_many :products
    
    validates :name, uniqueness: true
    has_and_belongs_to_many :product_pages, join_table: :spree_product_groups_product_pages
    belongs_to :country, class_name: 'Spree::Country'

    after_touch :touch_product_pages 
    after_save :touch_product_pages 

    def next_variant_in_stock
      Spree::Variant.
        in_stock.
        includes(:product).
        joins('LEFT OUTER JOIN spree_product_groups ON spree_product_groups.id = spree_products.product_group_id').
        where("spree_product_groups.id = ? AND spree_products.individual_sale = ? AND spree_variants.is_master = ?", self, true, false).
        references(:product).
        first
    end

    private

    def touch_product_pages
      product_pages.map(&:touch)
    end

  end
end
