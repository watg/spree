module Spree
  class ProductPageTab < ActiveRecord::Base
    TYPES = [:ready_to_wear, :knit_your_own]
    belongs_to :product_page

    validates_uniqueness_of :position, scope: :product_page_id
    validates :background_color_code, format: { with: /\A[A-Fa-f0-9]{6}\z/ }, allow_blank: true

    has_attached_file :banner,
      :styles        => { large: "3200x520>", mini: '320x52>' },
      :default_style => :large,
      :url           => "/spree/product_page_tabs/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/product_page_tabs/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' }

    process_in_background :banner

    include Spree::Core::S3Support
    supports_s3 :banner

    Spree::ProductPageTab.attachment_definitions[:banner][:default_url] = Spree::Config[:attachment_default_url]
    Spree::ProductPageTab.attachment_definitions[:banner][:default_style] = Spree::Config[:attachment_default_style]
    Spree::ProductPageTab.attachment_definitions[:banner][:s3_host_name] = Spree::Config[:s3_host_alias]


    def make_default(opts={})
      opts[:save] = true if opts[:save].nil?
      self.class.where(product_page_id: self.product_page_id).update_all(default: false)
      self.default = true
      self.save if opts[:save]
    end

    def banner_mini_url
      self.banner.url(:mini) rescue nil
    end
    def banner_url
      self.banner.url(:large) rescue nil
    end
  end
end
