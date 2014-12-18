module Spree
  class OptionType < ActiveRecord::Base
    has_many :option_values, -> { order(:position) }, dependent: :destroy, inverse_of: :option_type
    has_many :product_option_types, dependent: :destroy, inverse_of: :option_type
    has_many :products, through: :product_option_types
    has_and_belongs_to_many :prototypes, join_table: 'spree_option_types_prototypes'

    validates :name, :presentation, :sku_part, presence: true
    # default_scope -> { order("#{self.table_name}.position") }

    before_validation { update_presentation_and_sku_part }

    accepts_nested_attributes_for :option_values, reject_if: lambda { |ov| ov[:presentation].blank? and ov[:name].blank? }, allow_destroy: true

    after_touch :touch_all_products

    COLOUR = 'Colour'
    SIZE = 'Size'

    def touch_all_products
      products.find_each do |p|
        p.delay.touch
      end
    end

    def url_safe_name
      name.downcase.parameterize
    end

    def is_color?
      presentation == COLOUR
    end

    def is_size?
      presentation == SIZE
    end


    private

    def update_presentation_and_sku_part
      if self.name
        self.presentation = self.url_safe_name.split('-').map(&:capitalize).join(' ') if self.presentation.blank?
        self.sku_part = safe_sku if self.sku_part.blank?
      end
    end

    def safe_sku
      string = self.url_safe_name.split('-').map { |a| a[0..2].upcase }.join('_')

      numbers = Spree::OptionType.where("sku_part like '#{string}%'").map do |ot|
        matches = ot.sku_part.match(/^#{string}(_(\d+))?$/)
        matches ? matches[2].to_i : 0
      end

      if numbers.any?
        next_number = numbers.compact.sort.last + 1
        string = "#{string}_#{next_number}"
      end

      string
    end

  end
end
