module Spree
  class ProductPresenter < BasePresenter
    presents :product

    delegate :id, :name, :slug, :out_of_stock_override?, :product_type, to: :product

    SHIPPING_PARTIALS = { "CA" => "ca",
                          "CH" => "ch",
                          "ES" => "es",
                          "FR" => "fr",
                          "GB" => "gb",
                          "KR" => "kr",
                          "US" => "us" }

    def has_variants?
      @has_variant ||= product.has_variants?
    end

    def master
      @mater ||= product.master
    end

    def price
      @price ||= product.price_normal_in(currency)
    end

    def personalisations
      @personalisations ||= product.personalisations
    end

    def personalisation_images
      @personalisation_images ||= product.personalisation_images
    end

    def optional_parts_for_display
      @optional_parts_for_display ||= product.optional_parts_for_display
    end

    def variant_tree
      variant_options.tree
    end

    def option_type_order
      variant_options.option_type_order
    end

    def grouped_option_values_in_stock
      variant_options.grouped_option_values_in_stock
    end

    def option_types_and_values
      variant_options.option_types_and_values_for(sale_variant_or_first_variant_or_master)
    end

    def variant_option_values
      variant_options.variant_option_values
    end

    def variants
      @variants ||= product.variants_for(target).in_stock
    end

    def clean_description
      product.clean_description_for(target)
    end

    def images
      @images ||= product.images_for(target)
    end

    def variant_images
      @variant_images ||= product.variant_images_for(target)
    end

    def image_style
      is_mobile? ? :small : :product
    end

    def parts?
      product_parts.any?
    end

    def product_parts_images
      @product_parts_images ||= product.product_parts_images.with_target(target)
    end


    def product_parts
      @product_parts ||= product.product_parts
    end

    def video
      videos.any? && videos.first.embed
    end

    def videos
      @videos ||= product.videos
    end

    def delivery_partial
      pattern? ? "delivery_pattern" : country_specific_partial
    end

    def country_specific_partial
      if SHIPPING_PARTIALS[h.current_country_code]
        "delivery_#{SHIPPING_PARTIALS[h.current_country_code]}"
      else
        "delivery_default"
      end
    end

    def part_price_in_pence(part)
      method = (part.is_master ? :price_normal_in : :price_part_in)
      price = part.send(method, currency).price
      (price * 100 * part_quantity(part)).to_i
    end

    def part_quantity(part)
      @part_quantity ||= {}
      return @part_quantity[part] if @part_quantity[part]
      @part_quantity[part] = part.try(:count_part) || 1
      @part_quantity[part]
    end

    def sale_variant_or_first_variant_or_master
      @first_variant_or_master ||= begin
        variants.detect(&:in_sale) || variants.first || product.master
      end
    end

    private

    def build_variant_presenter(variant)
      VariantPresenter.new(variant, template, context)
    end

    def variant_options
      @variant_options ||= Spree::VariantOptions.new(variants, currency)
    end

    def pattern?
      product_type.pattern?
    end
  end
end
