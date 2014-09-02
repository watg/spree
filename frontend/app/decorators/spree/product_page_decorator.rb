class Spree::ProductPageDecorator < Draper::Decorator

  delegate_all

  def current_currency
    context[:current_currency] || @current_currency ||= Spree::Config[:currency]
  end

  def selected_tab
    context[:selected_tab] ||= object.tabs.made_by_the_gang.first
  end

  def selected_variant
    context[:selected_variant]
  end

  def tabs_as_permalinks
    object.tabs.map { |t| t.tab_type.gsub('_', '-').to_s.downcase }
  end

  def inverted_colour
    selected_tab && selected_tab.knit_your_own? ? 'inverted' : nil
  end

  def made_by_the_gang_variants( selected_variant=nil )
    selector = object.displayed_variants_in_stock
    if selected_variant
      selector = selector.reorder("
                        spree_variants.id = #{selected_variant.id} desc,
                        spree_product_page_variants.position asc,
                        spree_product_page_variants.id asc"
                      )
    end
    selector
  end

  def made_by_the_gang_variants?
    made_by_the_gang_variants.any?
  end

  def tags
    object.visible_tag_names
  end

  def tags?
    tags.any?
  end

  def render_tabs?
    # Show row if we have both gang made and knit your own
    made_by_the_gang_variants? && knit_your_own_product?
  end

  def made_by_the_gang_active_class
    selected_tab && selected_tab.made_by_the_gang? ? 'active' : ''
  end

  def knit_your_own_active_class
    selected_tab && selected_tab.knit_your_own? ? 'active' : ''
  end

  def active_tab(tab)
    (selected_tab == tab) ? 'active' : ''
  end

  def knit_your_own_product
    object.knit_your_own.product
  end

  def made_by_the_gang_product
    object.made_by_the_gang.product
  end

  def knit_your_own_product?
    knit_your_own_product.present?
  end

  def made_unique_title
    h.pluralize(2, object.title)[2..-1]
  end

  def row_hero_type
    selected_tab && selected_tab.made_by_the_gang? ? ' made-by-the-gang' : ' knit-your-own'
  end

  def made_by_the_gang_banner?
    made_by_the_gang_banner_url.present?
  end

  def made_by_the_gang_banner_url
    object.made_by_the_gang.banner_url
  end

  def made_by_the_gang_background_color
    object.made_by_the_gang.background_color_code
  end

  def made_by_the_gang_background_color?
    made_by_the_gang_background_color.present?
  end

  def knit_your_own_banner_url
    object.knit_your_own.banner_url
  end

  def knit_your_own_banner?
    knit_your_own_banner_url.present?
  end

  def knit_your_own_background_color
    object.knit_your_own.background_color_code
  end

  def knit_your_own_background_color?
    knit_your_own_background_color.present?
  end

  def hero_data_attributes
    data_attributes = []

    if made_by_the_gang_banner?
      data_attributes << %{data-hero-made-by-the-gang="#{made_by_the_gang_banner_url}"}
    end
    if knit_your_own_banner?
      data_attributes << %{data-hero-knit-your-own="#{knit_your_own_banner_url}"}
    end
    if made_by_the_gang_background_color?
      data_attributes << %{data-hero-made-by-the-gang-colour="#{made_by_the_gang_background_color}"}
    end
    if knit_your_own_background_color?
      data_attributes << %{data-hero-knit-your-own-colour="#{knit_your_own_background_color}"}
    end
    if selected_variant.present?
      data_attributes << %{data-selected-variant-id="#{selected_variant.id}"}
    end

    data_attributes.join(" ")
  end

  def title_size_class
    if object.title.split.first.length > 8 || object.title.split.last.length > 8
      "mini"
    elsif object.title.split.first.length == 8 || object.title.split.last.length == 8 || object.title.length >= 12
      "small"
    elsif object.title.length >= 10
      "medium"
    else
      "large"
    end
  end

  def knit_your_own_tab
    object.tabs.knit_your_own.first
  end

  def made_by_the_gang_tab
    object.tabs.made_by_the_gang.first
  end

  def url_encode_tab_name(tab)
    tab = object.made_by_the_gang if tab.blank?
    tab.url_safe_tab_type
  end

  def url_encoded_product_page_url(tab=nil)
     h.url_encode( h.spree.product_page_url(object.permalink,
                                            :host => h.root_url,
                                            :tab => url_encode_tab_name(tab)) )
  end

  def twitter_url(tab=nil)
    "http://twitter.com/intent/tweet?text=Presenting%20#{ h.url_encode(object.title) }%20by%20Wool%20and%20the%20Gang%3A%20#{ url_encoded_product_page_url(tab) }"
  end

  def facebook_url(tab=nil)
    "http://facebook.com/sharer/sharer.php?u=#{ url_encoded_product_page_url(tab) }"
  end

  def pinterest_url(tab=nil)
    url_link  =  if made_by_the_gang_banner?
                    h.url_encode(made_by_the_gang_banner_url)
                  elsif knit_your_own_banner?
                    h.url_encode(knit_your_own_banner_url)
                  end

    "http://pinterest.com/pin/create/%20button/?url=#{ url_encoded_product_page_url(tab) }&amp;media=#{ url_link }&amp;description=Presenting%20#{ h.url_encode(object.title) }%20by%20Wool%20and%20the%20Gang"
  end

  def facebook_image
    url_link =  if made_by_the_gang_banner?
                  made_by_the_gang_banner_url
                elsif knit_your_own_banner?
                  knit_your_own_banner_url
                end

    "#{ url_link }"
  end

end
