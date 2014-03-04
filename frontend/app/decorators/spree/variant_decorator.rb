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
    end
    data.join("<br>").html_safe
  end

  def target
    context[:target]
  end

  def memoized_product
    @_product ||= object.product
  end

  def selected_option_values
    @_selected_option_values ||= object.option_values.inject({}) { |hash,o| hash[o.option_type.url_safe_name] = o; hash }
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

  def first_image
    images = object.images_for(context[:target])
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

  def url_encoded_product_page_url(product_page)
    h.spree.product_page_url(product_page.permalink, :host => h.root_url, tab: product_page.tab, variant_id: object.id ) 
  end
  
  def twitter_url(product_page)
    "http://twitter.com/intent/tweet?text=Presenting%20#{ h.url_encode(object.name) }%20by%20Wool%20and%20the%20Gang%3A%20" + url_encoded_product_page_url(product_page)
  end

  def facebook_url(product_page)
    "http://facebook.com/sharer/sharer.php?u=" + url_encoded_product_page_url(product_page)
  end

  def pinterest_url(product_page)
    "http://pinterest.com/pin/create/%20button/?url=" + url_encoded_product_page_url(product_page) + "&amp;media=#{ h.url_encode(first_image_url(:medium)) }&amp;description=Presenting%20#{ h.url_encode(object.name) }%20by%20Wool%20and%20the%20Gang"
  end
  
  def level
    object.product.property('level')
  end

end
