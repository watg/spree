module Spree
  class ProductPage < ActiveRecord::Base
    validates_uniqueness_of :name, :permalink
    validates_presence_of :name, :title, :target_id

    has_and_belongs_to_many :product_groups, join_table: :spree_product_groups_product_pages

    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::ProductPageImage"
    has_many :products, through: :product_groups
    has_many :variants, through: :products, source: :all_variants_unscoped

    has_many :available_tags, -> { uniq }, through: :variants, class_name: "Spree::Tag", source: :tags
    has_many :taggings, as: :taggable
    has_many :tags, through: :taggings

    has_many :tabs, -> { order(:position) }, dependent: :destroy, class_name: "Spree::ProductPageTab"
    has_many :product_page_variants
    has_many :display_variants, through: :product_page_variants, class_name: "Spree::Variant", source: :variant

    has_many :index_page_items, as: :item, dependent: :delete_all
    has_many :index_pages, through: :index_page_items
    
    before_save :set_permalink

    def all_variants
      products.map(&:all_variants_or_master).flatten
    end

    def available_variants
      all_variants - display_variants
    end

    # def lowest_variant_price
    #   displayed_variants.active.joins(:prices).minimum(:amount)
    # end

    def ready_to_wear
      tab(:ready_to_wear)
    end

    def knit_your_own
      tab(:knit_your_own)
    end

    def kit_product
      products.where(product_type: :kit).first
    end


    def tab(tab_type)
      ( tabs.where(tab_type: tab_type).first || Spree::ProductPageTab.new(tab_type: tab_type, product_page_id: self.id))
    end

    def tag_names
      tags.pluck(:value)
    end

    private
    def set_permalink
      if self.permalink.blank? && self.name
        self.permalink = '/'+ name.downcase.split(' ').map{|e| (e.blank? ? nil : e) }.compact.join('-')
      end
    end
  end
end
