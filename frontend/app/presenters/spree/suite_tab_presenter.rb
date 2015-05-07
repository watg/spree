module Spree
  class SuiteTabPresenter < BasePresenter
    presents :suite_tab

    attr_accessor :suite, :variants
    delegate :cross_sales, to: :suite_tab

    def initialize(object, template, context={})
      super(object, template, context)
      @suite = context[:suite]
      @variants = context[:variants]
    end

    def product
      @product ||= suite_tab.product
    end

    def presentation
      @presentation ||= suite_tab.presentation
    end

    def cart_partial
      File.join('spree/suites/tab_type', suite_tab.partial)
    end

    def id
      suite_tab.id
    end

    def tab_type
      @tab_type ||= suite_tab.tab_type
    end

    def ready_made?
      self.tab_type == "made-by-the-gang"
    end

    def link_to
      @link_to ||= Spree::Core::Engine.routes.url_helpers.suite_url(
        id: suite.permalink, tab: suite_tab.tab_type)
    end

    def banner_url
      style = is_mobile? ? :mobile : :large
      @banner_url ||= suite_tab.image.attachment.url(style) if suite_tab.image
    end

    def inverted_colour
      @inverted_colour ||= (suite_tab.position % 2 == 0) ? 'inverted' : nil
    end

    def lowest_prices
      render_prices(lowest_normal_amount, lowest_sale_amount)
    end

    def twitter_url
      text = "#{social_description}: #{link_to}"
      "http://twitter.com/intent/tweet?text=#{url_encode(text)}"
    end

    def facebook_url
      "http://facebook.com/sharer/sharer.php?u=#{ url_encode(link_to) }"
    end

    def pinterest_url
      "http://pinterest.com/pin/create/%20button/?url=#{ url_encode(link_to) }&amp;media=#{ banner_url }&amp;description=#{ url_encode(social_description) }"
    end

    def in_stock?
      @in_stock ||= suite_tab.in_stock_cache
    end

    def variants_total_on_hand
      product.variants.inject({}) do |hash,v|
        total_on_hand = Spree::Stock::Quantifier.new(v).total_on_hand
        if total_on_hand < 6 and total_on_hand > 0
          hash[v.number] = total_on_hand
        end
        hash
      end
    end

    def meta_title
      suite_title = suite.meta_title.blank? ? suite.title : suite.meta_title
      marketing_meta_title = product.marketing_type.meta_title || product.marketing_type.title
      [suite_title, marketing_meta_title, 'WOOL AND THE GANG'].join(' | ')
    end

    def meta_keywords
       keywords = %w{Knitwear Knitting Knitted Wool Unique Handmade }
       keywords += ['Sustainable yarn', 'How to knit', 'Learn to knit']
       keywords << suite.title
       keywords << product.marketing_type.title
       keywords << product.meta_keywords
       keywords.uniq.join(", ")
    end
    def meta_description
      h.truncate(product.description, length: 160, separator: ' ')
    end

    def meta_name
      suite.name
    end

    def cross_sales_heading
      heading = {
        'yarn-and-wool' => 'What you can make',
        'knitting-pattern' => 'Knit this pattern',
        'made-by-the-gang' => 'More ready made goodness'
      }

      default = 'More WATG goodness'
      heading.fetch(tab_type, default)
    end

    private

    def social_description
      "Presenting #{suite.title} by Wool and the Gang"
    end

    def lowest_normal_amount
      suite_tab.lowest_normal_amount(currency)
    end

    def lowest_sale_amount
      suite_tab.lowest_sale_amount(currency)
    end

    def money_options
      {currency: currency}
    end

    def in_sale
      suite_tab.in_sale_cache
    end

    def render_prices(normal_amount, sale_amount)
      normal_money_amount = "from #{Spree::Money.new(normal_amount, money_options)}"
      if in_sale && sale_amount && ( sale_amount < normal_amount )
        sale_money_amount = "from #{Spree::Money.new(sale_amount, money_options)}"
        h.content_tag(:span, normal_money_amount.to_html, class: 'price was', itemprop: 'price') +
          h.content_tag(:span, sale_money_amount.to_html, class: 'price now')
      else
        h.content_tag(:span, normal_money_amount.to_html, class: 'price now', itemprop: 'price')
      end
    end
  end
end
