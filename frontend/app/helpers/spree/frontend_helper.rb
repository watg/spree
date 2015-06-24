module Spree
  module FrontendHelper

    def my_bag_link_mobile()
      if simple_current_order.nil? or simple_current_order.item_count.zero?
        text = "0"
      else
        text = "#{simple_current_order.item_count}"
      end

      link_to text.html_safe, spree.cart_path, :class => "link-cart"
    end

    def my_bag_link(text = nil)
      text = text ? h(text) : Spree.t('cart')
      css_class = nil

      if simple_current_order.nil? or simple_current_order.item_count.zero?
        text = "#{text}: (#{Spree.t('empty')})"
        css_class = 'empty'
      else
        text = "#{text}: (#{simple_current_order.item_count})  <span class='amount'>#{simple_current_order.display_total.to_html}</span>"
        css_class = 'full'
      end

      link_to text.html_safe, spree.cart_path, :class => "cart-info #{css_class}"
    end

  end
end
