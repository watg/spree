require File.join(Rails.root, 'lib/google_analytic.rb')
module Spree
  class AnalyticJob
    GA = GoogleAnalytic.new(YAML.load_file(File.join(Rails.root, 'config/ga.yaml'))[Rails.env])

    attr_reader :params, :user_id
    def initialize(params={})
      @params = params
      @user_id = params[:user_id]
    end

    def perform
      send(event)
    end

    def transaction
      # TODO: track: - sales discount
      # TODO: track: - b2b/affiliates discount [JL, ]
      # TODO: product collection [TS x watg, tartan, ...]
      if params[:order].completed_at
        GA.transaction(ga_transaction_details(params[:order], user_id))
        params[:order].line_items.each  {|i| GA.item(ga_item_details(i, user_id))}
        params[:order].adjustments.each {|i| GA.item(ga_adjustment_details(i, user_id))}
      end
    end

    def no_event_error
      raise "SUPPORTED event names: [transaction]"
    end

    private
    def event
      return @event if @event
      _e = params[:event].downcase.to_sym rescue :no_event_error
      @event = ( [:transaction, :no_event_error].include?(_e) ? _e : :no_event_error)
    end

    def ga_transaction_details(o, cid)
      {
        cid: cid,
        ti: o.number,
        tr: o.total.to_f,
        tt: o.tax.to_f,
        ts: o.shipments.last.cost.to_f,
      }
    end

    def ga_item_details(li, cid)
      {
        cid: cid,
        ti:  li.order.number,
        in:  li.variant.name,
        ip:  li.price.to_f,
        iq:  li.quantity,
        ic:  li.variant.sku,
        iv:  (li.variant.product.product_type.respond_to?(:name) ? li.variant.product.product_type.name : li.variant.product.product_type),
        cu:  li.order.currency
      }
    end

    def ga_adjustment_details(ad, cid)
      {
        cid: cid,
        ti:  ad.source.order.number,
        in:  ad.label,
        ip:  ad.amount.to_f,
        iq:  1,
        ic:  ad.originator.name,
        iv:  ad.originator_type,
        cu:  li.order.currency
      }
    end
    
  end
end
