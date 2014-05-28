module Spree
  class ProductPageTab < ActiveRecord::Base
    acts_as_paranoid

    KNIT_YOUR_OWN = 'knit_your_own'
    MADE_BY_THE_GANG = 'made_by_the_gang'

    TYPES = [MADE_BY_THE_GANG, KNIT_YOUR_OWN].map { |ppt| ppt.to_sym }

    belongs_to :product_page
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::ProductPageTabImage"
    has_and_belongs_to_many :marketing_types, :join_table => 'spree_product_page_tab_marketing_type'

    accepts_nested_attributes_for :image, allow_destroy: true

    validates_uniqueness_of :position, scope: :product_page_id
    validates :background_color_code, format: { with: /\A[A-Fa-f0-9]{6}\z/ }, allow_blank: true

    before_create :assign_position

    scope :made_by_the_gang, -> { where(tab_type: MADE_BY_THE_GANG) }
    scope :knit_your_own, -> { where(tab_type: KNIT_YOUR_OWN) }


    def self.to_tab_type(tab)
      tab.gsub(/-/,'_') unless tab.blank?
    end

    def made_by_the_gang?
      tab_type == MADE_BY_THE_GANG
    end

    def knit_your_own?
      tab_type == KNIT_YOUR_OWN
    end

    def assign_position
      self.position = (ProductPageTab.where(product_page: product_page).maximum(:position) || -1) + 1
    end

    def url_safe_tab_type
      tab_type.gsub(/_/,'-')
    end

    def make_default(opts={})
      opts[:save] = true if opts[:save].nil?
      self.class.where(product_page_id: self.product_page_id).update_all(default: false)
      self.default = true
      self.save if opts[:save]
    end

    def banner_mini_url
      if self.image
        self.image.attachment.url(:mini)
      end
    end

    def banner_url
      if self.image
        self.image.attachment.url(:large)
      end
    end
  end
end
