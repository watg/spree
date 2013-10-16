module Spree
  class ProductGroup < ActiveRecord::Base
    TABS = [:ready_to_wear, :knit_your_own]

    attr_accessible :name, :description, :title, :permalink, :taxon_ids
    validates :name, uniqueness: true
    validates :name, presence: true
    validates :permalink, uniqueness: true

    has_many :products
    has_many :tabs, order: :position, dependent: :destroy, class_name: "Spree::ProductGroupTab"

    before_save :set_permalink

    # This will help us clear the caches if a product is modified
    after_touch { self.delay.touch_taxons }

    def touch_taxons
      # You should be able to just call self.taxons.each { |t| t.touch } but
      # for some reason acts_as_nested_set does not walk all the ancestors
      # correclty
      self.taxons.each { |t| t.self_and_parents.each { |t2| t2.touch } }
    end

    def ready_to_wear_variants
      p = products.where(:product_type => 'ready_to_wear').includes(:variants)
      all_variants = p.inject([]) do |variants, product|
        if product.variants.size == 0
          variants + [product.master]
        else
          variants + product.variants
        end
      end
      all_variants.sort_by(&:created_at).reverse
    end

    def kit_product
      products.where(product_type: :kit).first
    end

    def tab(tab_type)
      ( tabs.where(tab_type: tab_type).first || Spree::ProductGroupTab.new(tab_type: tab_type, product_group_id: self.id))
    end

    private
    def set_permalink
      if self.permalink.blank? && self.name
        self.permalink = '/'+ name.downcase.split(' ').map{|e| (e.blank? ? nil : e) }.compact.join('-')
      end
    end
  end
end
