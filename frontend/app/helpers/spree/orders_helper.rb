require 'truncate_html'
require 'app/helpers/truncate_html_helper'

module Spree
  module OrdersHelper
    include TruncateHtmlHelper

    def linkshare_url(order)
      query_string = order.decorate.linkshare_params.
        inject([]) {|s, t|
          s << [t[0], t[1].join('|') ].join("="); s
        }.
        join('&')

      [LinkShare.base_url, query_string].join
    end

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
