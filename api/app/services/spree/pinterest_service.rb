module Spree
  module Api
    class PinterestRichPin
      def initialize(url)
        @product_url = url
      end

      def valid?
        url = @product_url.split("/")
        @product_permalink = url[url.index("products") + 1] if url
        return false unless @product_permalink
        variant_option_values = url[url.index("products") + 2, 5]
        
        load_product(@product_permalink)
        return false unless @product
        load_selected_variant(variant_option_values)
        return false unless @variant
        true
      end

      def get_result
        OpenStruct.new({
          provider_name: "Wool and the Gang",
          url: @product_url,
          title: @product.name,
          description: @product.description,
          product_id: @product_permalink,
          price: @variant.price,
          currency_code: @variant.currency,
          availability: @variant.in_stock? ? "in stock" : "out of stock"
        })
      end

    private    
        
      def load_product(permalink)
        @product = Product.find_by_permalink!(permalink)
      end

      def load_selected_variant(variant_option_values)
        if variant_option_values.blank?
          @variant = @product.master
        else
          @variant = Spree::Variant.options_by_product(@product, variant_option_values)
        end
        
        if !variant_option_values.blank? && (@variant.blank? || @variant.is_master)
          return false
        end
      end

    end
  end
end