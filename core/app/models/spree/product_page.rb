module Spree
  class ProductPage < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name, :permalink
    validates_presence_of :name, :title

    has_and_belongs_to_many :product_groups, join_table: :spree_product_groups_product_pages

    has_many :products, through: :product_groups
    has_many :variants, through: :products, source: :all_variants_unscoped

    has_many :index_page_items

    has_many :available_tags, -> { uniq }, through: :variants, class_name: "Spree::Tag", source: :tags
    has_many :taggings, as: :taggable
    has_many :tags, through: :taggings

    has_many :tabs, -> { order(:position) }, dependent: :destroy, class_name: "Spree::ProductPageTab"
    has_many :product_page_variants
    has_many :displayed_variants, through: :product_page_variants, class_name: "Spree::Variant", source: :variant
    has_many :displayed_variants_in_stock , -> {
      joins("LEFT OUTER JOIN spree_stock_items ON spree_stock_items.variant_id = spree_product_page_variants.variant_id").
      where("spree_stock_items.count_on_hand > 0")
    },
    through: :product_page_variants,
    class_name: "Spree::Variant",
    source: :variant

    belongs_to :target

    before_validation :set_permalink
    after_create :create_tabs
    after_touch :touch_index_page_items

    accepts_nested_attributes_for :tabs, allow_destroy: true

    def all_variants
      products.where("product_type <> 'virtual_product' ").map(&:all_variants_or_master).flatten
    end

    def non_kit_variants_with_target
      all_variants.select do |v|
        keep = v.product.product_type != 'kit'
        if self.target.present?
          keep = keep && v.targets.include?(self.target)
        end
        keep
      end
    end


    def lowest_priced_made_by_the_gang(currency = nil)
      displayed_variants_in_stock.active(currency).joins(:prices).order("spree_prices.amount").first
    end

    def lowest_priced_kit(currency = nil)
      kit_product.lowest_priced_variant
    end

    def create_tabs
      tabs.create(tab_type: :made_by_the_gang)
      tabs.create(tab_type: :knit_your_own)
    end

    def available_variants
      non_kit_variants_with_target - displayed_variants
    end

    def made_by_the_gang
      tab(:made_by_the_gang)
    end

    def knit_your_own
      tab(:knit_your_own)
    end

    #TODO add targeting and add a test
    def kit_product
      products.where(product_type: :kit).first
    end

    def tab(tab_type)
      tabs.where(tab_type: tab_type).first
    end

    def tag_names
      tags.pluck(:value)
    end

    def visible_tag_names
      Spree::Tag.
        joins("LEFT JOIN spree_taggings ON spree_taggings.tag_id = spree_tags.id AND spree_taggings.taggable_type= 'Spree::Variant'").
        joins("LEFT JOIN spree_product_page_variants ON spree_product_page_variants.variant_id = spree_taggings.taggable_id ").
        where("spree_product_page_variants.product_page_id = (?)", self.id).
        uniq.
        pluck(:value)
    end

    private
    def set_permalink
      if self.permalink.blank? && self.name
        self.permalink = name.downcase.split(' ').map{|e| (e.blank? ? nil : e) }.compact.join('-')
      end
    end

    def touch_index_page_items
      index_page_items.each { |item| item.touch }
    end
  end
end
