module Spree
  class PinterestService < Mutations::Command
    # new api
    # http://0.0.0.0:3000/shop/api/pinterest/?url=http://0.0.0.0:3000/shop/items/zion-lion-men/made-by-the-gang/879
    # old api
    # http://0.0.0.0:3000/shop/api/pinterest/?url=http://0.0.0.0:3000/shop/products/florence-sweater-1/ivory-white

    required do
      string :url
    end

    def execute

      if url.match(/products\/(.*)/)
        url_parts = $1.split("/")
        old_api( *url_parts )
      elsif url.match(/items\/(.*)/)
        url_parts = $1.split("/")
        new_api( *url_parts )
      else
        add_error(:url, :could_not_parse_url, "Could not parse url")
      end
    end

    def old_api(product_slug, variant_option_values)
      return if has_errors?

      product = load_product(product_slug) if product_slug
      if !product
        add_error(:url, :could_not_find_product, "Could not find product")
        return
      end

      variant = load_selected_variant(product, variant_option_values)
      if !variant
        add_error(:url, :could_not_find_variant, "Could not find variant")
        return
      end

      tab = if variant.product.product_type.kit?
              Spree::ProductPageTab::KNIT_YOUR_OWN
            else
              Spree::ProductPageTab::MADE_BY_THE_GANG
            end

      OpenStruct.new({
        provider_name: "Wool and the Gang",
        url: url,
        title: fancy_title(product.name, tab),
        description: product.description,
        product_id: product_slug,
        price: variant.current_price_in("GBP").amount,
        currency_code: "GBP",
        availability: variant.in_stock_cache ? "in stock" : "out of stock"
      })
    end

    def new_api(product_page_slug, product_page_tab=nil, variant_id=nil)
      return if has_errors?


      product_page = load_product_page(product_page_slug) if product_page_slug
      if !product_page
        add_error(:url, :could_not_find_product_page, "Could not find product page")
        return
      end

      product_page_tab ||=  Spree::ProductPageTab::MADE_BY_THE_GANG
      product_page_tab.gsub!('-','_')

      variant = nil
      variant = find_variant(variant_id, product_page_tab, product_page)

      if !variant
        add_error(:url, :could_not_find_variant, "Could not find product page")
        return
      end

      product = variant.product.decorate

      OpenStruct.new({
        provider_name: "Wool and the Gang",
        url: url,
        title: fancy_title(product.name, product_page_tab),
        description: product.clean_description_for(product_page.target),
        product_id: variant.number,
        price: variant.current_price_in("GBP").amount,
        currency_code: "GBP",
        availability: variant.in_stock_cache ? "in stock" : "out of stock",
        gender: gender(product_page.target),
        # Only supply the first 6 images
        images: variant.images_for(product_page.target).first(6)
      })

    end

    private

    def find_variant(variant_id, product_page_tab, product_page)
      variant = nil
      if variant_id
        variant = load_variant(variant_id)
      else

        if tabs = product_page.tabs.where(tab_type: product_page_tab)
          if products = tabs.map(&:product).flatten.compact
            if variants = products.map(&:variants).flatten.compact
              variant = variants.first
            end
          end
        end
        variant ||= product_page.variants.first

      end
      variant
    end

    def gender(target)
      return 'unisex' unless target
      target.name.downcase
    end

    def load_product_page(permalink)
      ProductPage.where(permalink: permalink).first
    end

    def load_variant(variant_id)
      if Spree::Variant.is_number(variant_id)
        selected_variant = Spree::Variant.where(number: variant_id).first
      else
        selected_variant = Spree::Variant.where(id: variant_id).first
      end
    end

    def load_product(slug)
      Product.where(slug: slug).first
    end

    def load_selected_variant(product, variant_option_values)
      if variant_option_values.blank?
        variant = product.master
      else
        variant = Spree::Variant.options_by_product(product, variant_option_values)
      end

      variant
    end

    def fancy_title(product_name, product_page_tab)
      case product_page_tab.gsub('-','_')
      when Spree::ProductPageTab::KNIT_YOUR_OWN
        product_name + " Knit Kit"
      when Spree::ProductPageTab::MADE_BY_THE_GANG
        product_name + ' #madeunique by The Gang'
      else
        product_name
      end
    end

  end
end
