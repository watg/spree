class Spree::IndexPageItemDecorator < Draper::Decorator
  delegate_all

  def current_currency
    context[:current_currency]
  end

  def image_url(counter = 0 )
    style = counter % 9 == 0 ? :large : :small

    if memoized_image.present?
      memoized_image.attachment.url(style)
    else
      h.image_path("product-group/placeholder-470x600.gif")
    end
  end

  def image_alt
    memoized_image.try(:alt)
  end

  def header_style
    case object.template_id
    when Spree::IndexPageItem::LARGE_TOP
      classes = "large top"
    when Spree::IndexPageItem::SMALL_BOTTOM
      classes = "small bottom"
    else
      classes = "small bottom"
    end

    if object.inverted?
      classes += " inverted"
    end

    classes
  end

  def made_by_the_gang_link?
    ( memoized_variant.present? && ! memoized_variant_is_kit? && memoized_variant_in_stock? ) ||
    ( memoized_product_page.present? && memoized_product_page.displayed_variants_in_stock.any? )
  end

  def memoized_variant_in_stock?
    @_memoized_variant_in_stock ||= memoized_variant.in_stock_cache
  end

  def made_by_the_gang_url
    if memoized_variant.present? && memoized_variant_in_stock? 
      product_page_url("made-by-the-gang", memoized_variant.id)
    else
      product_page_url("made-by-the-gang")
    end
  end

  def memoized_variant_in_sale?
    @_memoized_variant_in_sale ||= memoized_variant.in_sale? 
  end

  def knit_your_own_prices
    flavour_prices(:knit_your_own)
  end

  def made_by_the_gang_prices
    flavour_prices(:made_by_the_gang)
  end
  
  def flavour_prices(flavour)
    if memoized_variant.present?

      if memoized_variant_in_stock?

        lowest_price = memoized_variant.price_normal_in(current_currency)
        if memoized_variant_in_sale?
          sale_price = memoized_variant.price_normal_sale_in(current_currency)
        end
        render_prices(lowest_price, sale_price, nil)
      else

        render_out_of_stock
      end
    else
      if flavour == :knit_your_own &&  memoized_product_page.kit.present?

        item = object.product_page.kit.master
       
        lowest_price = item.prices.select{ |price| price.currency == current_currency && price.sale == false && (price.is_kit == false) }.first
        if item.in_sale?
          sale_price = item.prices.select{ |price| price.currency == current_currency && price.sale == true && (price.is_kit == false) }.first
        end

        render_prices(lowest_price, sale_price, nil)        
      else

      lowest_price = memoized_product_page.lowest_normal_price(current_currency, flavour)
      highest_price = memoized_product_page.highest_normal_price(current_currency, flavour)

      lowest_sale_price = memoized_product_page.lowest_sale_price(current_currency, flavour)
      render_prices(lowest_price, lowest_sale_price, highest_price)
      end
    end
  end

  def render_prices(lowest_price, sale_price, highest_price)
    # This has been commented out for the time being to see if it drives
    # more conversion, DD 23/01/14
    #if highest_price
      prefix = 'from'# if lowest_price.amount != highest_price.amount
    #end
    if lowest_price
      price = "#{prefix} #{lowest_price.display_price}"
      if sale_price && ( sale_price.amount < lowest_price.amount )
        h.content_tag(:span, price.to_html, class: 'price was', itemprop: 'price') +
          h.content_tag(:span, sale_price.display_price.to_html, class: 'price now')
      else
        h.content_tag(:span, price.to_html, class: 'price now', itemprop: 'price')
      end
    else
      render_out_of_stock
    end
  end

  def render_out_of_stock
      h.content_tag(:span, 'out-of-stock', class: 'price', itemprop: 'price')
  end

  def knit_your_own_link?
    ( variant_knit_your_own? && memoized_variant_in_stock? ) || 
    ( product_page_knit_your_own? &&  memoized_product_page.kit.variants.active(current_currency).in_stock.any?  ) ||
    ( product_page_knit_your_own? && memoized_product_page.kit.assembly_definition )
  end

  def knit_your_own_url
    if memoized_variant.present?
      product_page_url("knit-your-own", memoized_variant.id)
    else
      product_page_url("knit-your-own")
    end
  end

  def variant_knit_your_own?
    memoized_variant.present? && memoized_variant_is_kit?
  end

  def product_page_knit_your_own?
      memoized_product_page.present? && memoized_product_page.kit.present?
  end

  def memoized_variant_is_kit?
    @_variant_is_kit ||= memoized_variant.product.product_type == 'kit'
  end

  def memoized_product_page?
    memoized_product_page.present?
  end

  def memoized_product_page
    @_product_page ||= object.product_page
  end

  def memoized_variant
    @_variant ||= object.variant
  end

  def memoized_image
    @_image ||= object.image
  end

  def product_page_url(tab, variant_id = nil)
    h.product_page_path(id: memoized_product_page.permalink, tab: tab, variant_id: variant_id) if memoized_product_page && memoized_product_page.permalink.present?
  end
end
