module Spree
  class OptionValue < ActiveRecord::Base

    belongs_to :option_type, class_name: 'Spree::OptionType', touch: true, inverse_of: :option_values
    acts_as_list scope: :option_type
    has_and_belongs_to_many :variants, join_table: 'spree_option_values_variants', class_name: "Spree::Variant"

    validates :name, presence: true
    validates_uniqueness_of :name, :scope => [:option_type_id]
    validates_uniqueness_of :sku_part, :scope => [:option_type_id]

    #validate :name_is_url_safe

    default_scope { order("#{quoted_table_name}.position") }

    before_create { update_presentation_and_sku_part }

    after_touch :touch_all_variants

	# The URL parameter should be changed from 'products' to 'option_value' at some point
    has_attached_file :image,
    :styles        => { :small => '18x18#', :medium => '40x30#', :large => '140x110#' },
    :default_style => :small
#    TODO: move options values in option_values folder on S3
    
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

    def update_presentation_and_sku_part
      if self.name
        self.presentation = self.url_safe_name.split('-').map(&:capitalize).join(' ') if self.presentation.blank?
        self.sku_part = safe_sku if self.sku_part.blank?
      end
    end

    # Ensure the sku_part is generated uniq
    def safe_sku
      string = self.url_safe_name.split('-').map { |a| a[0..1].upcase }.join('_')

      # This is an optimistaion to deal with the nested_attributes which we have to deal with
      # we first check the in memory data structure, then followed by the DB
      option_values = option_type.option_values.select { |ov| ov.sku_part.to_s.match(/^#{string}/) }
      option_values += Spree::OptionValue.where(option_type_id: option_type.id).where("sku_part like '#{string}%'")

      numbers = option_values.uniq.map do |ov|
        if matches = ov.sku_part.to_s.match(/^#{string}(_(\d+))?$/)
          matches ? matches[2].to_i : 0
        end
      end

      if numbers.any?
        next_number = numbers.compact.sort.last + 1
        string = "#{string}_#{next_number}"
      end

      string
    end

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
