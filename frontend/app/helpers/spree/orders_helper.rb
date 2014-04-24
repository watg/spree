module Spree
  module OrdersHelper
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

  end
end
