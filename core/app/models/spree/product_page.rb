module Spree
  class ProductPage < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name, :permalink
    validates_presence_of :name, :permalink, :title

    belongs_to :kit, class_name: "Spree::Product", dependent: :destroy
    
    has_and_belongs_to_many :product_groups, join_table: :spree_product_groups_product_pages

    has_many :products, through: :product_groups
    has_many :variants, through: :products, source: :all_variants_unscoped
    has_many :taxons, as: :page
    has_many :index_page_items

    has_many :available_tags, -> { uniq }, through: :variants, class_name: "Spree::Tag", source: :tags
    has_many :taggings, as: :taggable
    has_many :tags, through: :taggings

    has_many :tabs, -> { order(:position) }, dependent: :destroy, class_name: "Spree::ProductPageTab"
    has_many :product_page_variants
    has_many :displayed_variants, through: :product_page_variants, class_name: "Spree::Variant", source: :variant

    belongs_to :target

    after_create :create_tabs

    after_save :touch_index_page_items
    after_touch :touch_index_page_items

    accepts_nested_attributes_for :tabs, allow_destroy: true

    make_permalink

    def displayed_variants_in_stock
      displayed_variants.in_stock
    end

    # made by the gang selected
    def non_kit_variants_with_target
      result = products.where(marketing_type_id: made_by_the_gang.marketing_type_ids).map(&:all_variants_or_master).flatten
      if self.target_id.present?
        result = result.select {|variant| variant.target_ids.include? self.target_id }
      end
      result
    end

    def banner_url
      url = made_by_the_gang.banner_url
      url ||= knit_your_own.banner_url
      url
    end

    def highest_normal_price(currency, flavour)
      variant_prices(flavour, currency, in_sale: false).last
    end

    def lowest_normal_price(currency, flavour)
      variant_prices(flavour, currency, in_sale: false).first
    end

    def lowest_sale_price(currency, flavour)
      variant_prices(flavour, currency, in_sale: true).first
    end

    def create_tabs
      tabs.create(tab_type: Spree::ProductPageTab::MADE_BY_THE_GANG)
      tabs.create(tab_type: Spree::ProductPageTab::KNIT_YOUR_OWN)
    end

    def available_variants
      non_kit_variants_with_target - displayed_variants
    end

    def made_by_the_gang
      tab(Spree::ProductPageTab::MADE_BY_THE_GANG)
    end

    def knit_your_own
      tab(Spree::ProductPageTab::KNIT_YOUR_OWN)
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
    
    def to_param
      permalink.present? ? permalink.to_s.to_url : name.to_s.to_url
    end

    private

    def variants_for_flavour(flavour, currency)
      if flavour == :made_by_the_gang
        displayed_variants.in_stock.active(currency)
      elsif flavour == :knit_your_own
        kit.variants.in_stock.active(currency)
      end
    end

    def variant_prices(flavour, currency, in_sale: false)
      variants = variants_for_flavour(flavour, currency)

      selector = Spree::Price.where('spree_prices.currency = ? and sale = ? and is_kit = ?', currency, in_sale, false )
       .where(variant_id: variants.map(&:id) ).joins(:variant)

      selector = selector.where('spree_variants.in_sale = ?', in_sale) if in_sale == true

      selector.reorder('amount')
    end

    def touch_index_page_items
      index_page_items.each { |item| item.touch }
    end

  end
end
