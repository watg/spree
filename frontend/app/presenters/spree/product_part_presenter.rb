module Spree
  class ProductPartPresenter < BasePresenter
    presents :product_part
    delegate :id, :optional?, :count, :presentation, to: :product_part

    def variants
      @variants ||= product_part.variants.in_stock
    end

    def first_variant
      variants.first
    end

    def product_name
      @product_name ||= product_part.part.name
    end

    def displayable_option_type
      @displayable_option_type ||= product_part.displayable_option_type
    end

    #### option value methods ####

    def option_value_tree
      variant_options.option_value_simple_tree
    end

    def simple_tree
      variant_options.variant_simple_tree
    end

    ########### Variant option object methods ####################

    def variant_option_objects
      variants.map do |v|
        ::VariantPartOptions.new(v, displayable_option_type)
      end
    end

    #### option value methods ####

    def variant_tree
      variant_options.option_value_simple_tree
    end

    def displayable_option_values
      @displayable_option_values ||= variant_options.option_values_in_stock
    end

    private

    def variant_options
      @variant_options ||= Spree::VariantOptions.new(variants, currency, displayable_option_type)
    end

    def all_part_images_present
      variants.all? { |v| v.part_image.present? }
    end
  end
end
