class Spree::VariantDecorator < Draper::Decorator
  delegate_all
  
  def color_and_size_option_values
    hash = object.option_values.group_by(&:option_type)
    hash.inject({}) {|hsh, t| 
      key = t[0].name.downcase.to_sym
      key = :color if key == :colour
      hsh[key] = t.last
      hsh
    }
  end

  def price_with_currency
    "#{price.amount.to_f} #{currency}"
  end
  
  def current_currency
    context[:current_currency] || Spree::Config[:currency]
  end

  def display_name_including_options
    data = [ object.name ]
    if object.display_name
      data.unshift object.display_name
      if data.first.blank?
        data.shift
      end
    end
    data.join("<br>").html_safe
  end

  def target
    context[:target]
  end

  def clean_description
    object.product.clean_description_for(target)
  end

  def memoized_product
    @_product ||= object.product
  end

  def selected_option_values
    @_selected_option_values ||= object.option_values.inject({}) { |hash,o| hash[o.option_type.url_safe_name] = o; hash }
  end

  def kit_price_in_pence(currency,count)
    (object.kit_price_in(currency) * 100 * count ).to_i
  end

  def gang_member
    object.product.memoized_gang_member
  end

  def price
    object.price_normal_in(context[:current_currency])
  end

  def price_html
    price.display_price.to_html
  end

  def sale_price
    object.price_normal_sale_in(context[:current_currency])
  end

  def sale_price_html
    sale_price.display_price.to_html
  end

  def currency_symbol
    price.currency_symbol
  end

  def has_price?
    price.present?
  end

  def normal_price_classes
    if object.in_sale?
      ['normal-price','was'].join(' ')
    else
      ['normal-price', 'price', 'selling'].join(' ')
    end
  end

  def sale_price_classes
    if object.in_sale?
      ['sale-price','price', 'now', 'selling'].join(' ')
    else
      ['sale-price', 'hide'].join(' ')
    end
  end

  def memoized_first_image
    @memoized_first_image ||= first_image
  end

  def assembly_definition_images
     selector = object.assembly_definition.images
     if target.blank?
       selector = selector.where( target_id: nil )
     else
       selector = selector.where( target: target )
     end
     selector
  end

  def first_image
    images = object.images_for(target)
    if images.blank?
      if object.product.memoized_images.empty?
        nil
      else
        object.product.memoized_images.first
      end
    else
      images.first
    end
  end

  def memoized_first_image_url(style)
    @memoized_first_image_url ||= {}
    @memoized_first_image_url[style] ||= first_image_url(style)
  end

  def first_image_url(style = :small)
    image = first_image
    if image.present?
      image.attachment.url(style)
    else
      h.image_path('product-group/placeholder-470x600.gif')
    end
  end

  def first_image_alt
    first_image.try(:alt)
  end

  def tag_names?
    object.tag_names.present?
  end

  def safe_tag_list
    h.safe_tag_list(object.tag_names)if tag_names?
  end

  def display_price
    if object.in_sale?
      sale_price.display_price.to_s[1..-1]
    else
      price.display_price.to_s[1..-1]
    end
  end

  def placeholder_image
      h.image_path('product-group/placeholder-470x600.gif')
  end

  def memoized_placeholder_image_alt
    @_placeholder_images_alt ||= placeholder_image_alt
  end

  def placeholder_image_alt
    object.name + ' by ' + gang_member.nickname
  end

  def placeholder_thumbnails
    h.image_path('product-group/placeholder-66x84.gif')
  end

  def has_more_than_one_image?
     (object.memoized_product.images + object.product.memoized_variant_images).uniq.size > 1
  end

  def url_encode_tab_name(tab)
    return 'made-by-the-gang' if tab.blank?
    tab.to_s.gsub(/_/, '-')
  end

  def url_encoded_product_page_url(product_page, tab=nil)
    h.spree.product_page_url(product_page.permalink, 
                             :host => h.root_url, 
                             tab: url_encode_tab_name(tab) || product_page.tab, 
                             variant_id: object.number ) 
  end
  
  def twitter_url(product_page, tab=nil)
    "http://twitter.com/intent/tweet?text=Presenting%20#{ h.url_encode(object.name) }%20by%20Wool%20and%20the%20Gang%3A%20" + url_encoded_product_page_url(product_page,tab)
  end

  def facebook_url(product_page, tab=nil)
    "http://facebook.com/sharer/sharer.php?u=" + url_encoded_product_page_url(product_page,tab)
  end

  def pinterest_url(product_page, tab=nil)
    "http://pinterest.com/pin/create/%20button/?url=" + url_encoded_product_page_url(product_page,tab) + "&amp;media=#{ h.url_encode(first_image_url(:large)) }&amp;description=Presenting%20#{ h.url_encode(object.name) }%20by%20Wool%20and%20the%20Gang"
  end
  
  def level
    object.product.property('level')
  end

end
