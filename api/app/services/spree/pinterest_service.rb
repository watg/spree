module Spree
  class PinterestService < Mutations::Command
    # http://0.0.0.0:3000/shop/products/florence-sweater/ivory-white

    required do
      string :url
    end

    def execute
      product_permalink, variant_option_values = parse_url
      if has_errors?
        return
      end

      product = load_product(product_permalink) if product_permalink
      if !product
        add_error(:url, :could_not_find_product, "Could not find product")
        return
      end

      variant = load_selected_variant(product, variant_option_values)
      if !variant
        add_error(:url, :could_not_find_variant, "Could not find variant")
        return
      end

      OpenStruct.new({
        provider_name: "Wool and the Gang",
        url: url,
        title: fancy_title(product.name, variant),
        description: product.description,
        product_id: product_permalink,
        price: variant.current_price_in("GBP").amount,
        currency_code: "GBP",
        availability: variant.in_stock_cache ? "in stock" : "out of stock"
      })

    end

  
  private

    def parse_url
      url_parts = url.match /products\/(.*)/
      if url_parts
        url_parts = url_parts[1].split("/") 
        product_permalink = url_parts.shift
      else
        add_error(:url, :could_not_parse_url, "Could not parse url")
        return
      end

      [product_permalink, url_parts]
    end
      
    def load_product(permalink)
      Product.find_by_slug(permalink)
    end

    def load_selected_variant(product, variant_option_values)
      if variant_option_values.blank?
        variant = product.master
      else
        variant = Spree::Variant.options_by_product(product, variant_option_values)
      end
      
      variant
    end

    def fancy_title(product_name, variant)
      if ['kit','virtual_product'].include? variant.product_type 
        product_name + " Knit Kit"
      elsif !variant.isa_part?
        product_name + ' #madeunique by The Gang'
      else
        product_name
      end
    end

  end
end
