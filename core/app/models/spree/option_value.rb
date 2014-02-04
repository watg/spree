module Spree
  class OptionValue < ActiveRecord::Base
    belongs_to :option_type, :class_name => 'Spree::OptionType', :touch => true
    acts_as_list scope: :option_type
    has_and_belongs_to_many :variants, join_table: 'spree_option_values_variants', class_name: "Spree::Variant"

    validates :name, :presentation, presence: true
    validates_uniqueness_of :name, :scope => [:option_type_id]

    validate :name_is_url_safe

    # from variant options

    default_scope { order("#{quoted_table_name}.position") }

    after_touch :touch_all_variants

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

    # At some point we may want to turn auto formatting on
    #def name=(val)
    #  write_attribute(:name, val.gsub(/\W+/,'-').downcase)
    #end
    
    def has_image?
      image_file_name && !image_file_name.empty?
    end
    
    scope :for_product, lambda { |product, stock|
      v_ids = (stock ? product.variants_in_stock : product.variants).map(&:id)
      select("#{table_name}.*").
      where("spree_option_values_variants.variant_id IN (?)", v_ids).references(:option_values_variants).
      joins(:variants).uniq
    }

    scope :with_target, lambda {|target|
      joins("LEFT OUTER JOIN spree_variant_targets ON spree_variants.id = spree_variant_targets.variant_id").
      joins("LEFT OUTER JOIN spree_targets ON spree_targets.id = spree_variant_targets.target_id").
      where("spree_variant_targets.target_id = (?)", target.id)
    }

    def url_safe_name
      name.downcase.parameterize
    end

    private

    def name_is_url_safe
      if Rack::Utils.escape_path(name) != name
        errors.add(:name, "[#{name}] is not url safe")
      end
    end

    def touch_all_variants
      # This can cause a cascade of products to be updated
      # To disable it in Rails 4.1, we can do this:
      # https://github.com/rails/rails/pull/12772
      # Spree::Product.no_touching do
        variants.find_each(&:touch)
      # end
    end
    
  end
end
