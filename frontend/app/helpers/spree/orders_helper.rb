require 'truncate_html'
require 'app/helpers/truncate_html_helper'

module Spree
  module OrdersHelper
    include TruncateHtmlHelper

    def order_just_completed?(order)
      flash[:order_completed] && order.present?
    end

    def truncated_product_description(product)
      truncate_html(raw(product.description))
    end

    def order_just_completed?(order)
      flash[:order_completed] && order.present?
    end

    def referring_page
      last_page = request.referrer
      last_page ? last_page : root_path
    end

  end
end
