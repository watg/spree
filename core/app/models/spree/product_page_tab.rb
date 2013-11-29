module Spree
  class ProductPageTab < ActiveRecord::Base
    TYPES = [:ready_to_wear, :knit_your_own]

    belongs_to :product_page
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::ProductPageTabImage"

    validates_uniqueness_of :position, scope: :product_page_id
    validates :background_color_code, format: { with: /\A[A-Fa-f0-9]{6}\z/ }, allow_blank: true

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
