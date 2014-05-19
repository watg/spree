module Spree
  class ProductPageTab < ActiveRecord::Base
    acts_as_paranoid

    KNIT_YOUR_OWN = 'knit_your_own'
    MADE_BY_THE_GANG = 'made_by_the_gang'

    TYPES = [MADE_BY_THE_GANG, KNIT_YOUR_OWN].map { |ppt| ppt.to_sym }

    belongs_to :product_page
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::ProductPageTabImage"

    accepts_nested_attributes_for :image, allow_destroy: true

    validates_uniqueness_of :position, scope: :product_page_id
    validates :background_color_code, format: { with: /\A[A-Fa-f0-9]{6}\z/ }, allow_blank: true

    before_create :assign_position

    def assign_position
      self.position = (ProductPageTab.where(product_page: product_page).maximum(:position) || -1) + 1
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
