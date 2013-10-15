module Spree
  class OptionValue < ActiveRecord::Base
    belongs_to :option_type, touch: true
    acts_as_list scope: :option_type
    has_and_belongs_to_many :variants, join_table: 'spree_option_values_variants', class_name: "Spree::Variant"

    validates :name, :presentation, presence: true
    validates_uniqueness_of :name, :scope => [:option_type_id]

    validate :name_is_url_safe

    # from variant options

    default_scope { order("#{quoted_table_name}.position") }

    has_attached_file :image,
    :styles        => { :small => '18x18#', :medium => '40x30#', :large => '140x110#' },
    :default_style => :small,
    :url           => "/spree/option_values/:id/:style/:basename.:extension",
    :path          => ":rails_root/public/spree/option_values/:id/:style/:basename.:extension"
    
    include Spree::Core::S3Support
    supports_s3 :image
    
    Spree::OptionValue.attachment_definitions[:image][:styles] = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles]).symbolize_keys!
    Spree::OptionValue.attachment_definitions[:image][:path] = Spree::Config[:attachment_path]
    Spree::OptionValue.attachment_definitions[:image][:url] = Spree::Config[:attachment_url]
    Spree::OptionValue.attachment_definitions[:image][:default_url] = Spree::Config[:attachment_default_url]
    Spree::OptionValue.attachment_definitions[:image][:default_style] = Spree::Config[:attachment_default_style]
    Spree::OptionValue.attachment_definitions[:image][:s3_host_name] = "s3-eu-west-1.amazonaws.com"

    # At some point we may want to turn auto formatting on
    #def name=(val)
    #  write_attribute(:name, val.gsub(/\W+/,'-').downcase)
    #end
    
    def has_image?
      image_file_name && !image_file_name.empty?
    end
    
    scope :for_product, lambda { |product|
      select("DISTINCT #{table_name}.*").where("spree_option_values_variants.variant_id IN (?)", product.variant_ids).joins(:variants)
    }

    # end variant options
    
    # This invalidates the variants cache
    after_save { self.delay.touch_variants }

    private

    def name_is_url_safe
      if Rack::Utils.escape_path(name) != name
        errors.add(:name, "[#{name}] is not url safe")
      end
    end

    def touch_variants
      self.variants.each { |v| v.touch }
    end
    
  end
end
