module Spree
  class ProductGroupTab < ActiveRecord::Base
    attr_accessible :tab_type, :product_group_id

    TYPES = [:ready_to_wear, :knit_your_own]
    belongs_to :product_group
    
    has_many :classifications, dependent: :delete_all
    has_many :taxons, through: :classifications

    validates_uniqueness_of :default,  scope: :product_group_id, if: Proc.new {|tab| tab.default }
    validates_uniqueness_of :position, scope: :product_group_id

    # This will help us clear the caches if a product is modified
    after_touch { self.delay.touch_taxons }

    has_attached_file :banner,
      :styles        => { large: "3200x520>", mini: '320x52>' },
      :default_style => :large,
      :url           => "/spree/product_group_tabs/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/product_group_tabs/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' }

    process_in_background :banner

    include Spree::Core::S3Support
    supports_s3 :banner

    Spree::ProductGroupTab.attachment_definitions[:banner][:default_url] = Spree::Config[:attachment_default_url]
    Spree::ProductGroupTab.attachment_definitions[:banner][:default_style] = Spree::Config[:attachment_default_style]
    Spree::ProductGroupTab.attachment_definitions[:banner][:s3_host_name] = Spree::Config[:s3_host_alias]


    def touch_taxons
      # You should be able to just call self.taxons.each { |t| t.touch } but
      # for some reason acts_as_nested_set does not walk all the ancestors
      # correclty
      self.taxons.each { |t| t.self_and_parents.each { |t2| t2.touch } }
    end

    def make_default(opts={})
      opts[:save] = true if opts[:save].nil?
      self.class.where(product_group_id: self.product_group_id).update_all(default: false)
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
