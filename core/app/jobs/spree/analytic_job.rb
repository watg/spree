require File.join(Rails.root, 'lib/google_analytic.rb')
require File.join(Rails.root, 'lib/runners/analytics/helpers.rb')
module Spree
  class AnalyticJob
    include AnalyticManual::Helpers

    GA = GoogleAnalytic.new(YAML.load_file(File.join(Rails.root, 'config/ga.yaml'))[Rails.env])
    #   Latency
    #   var metricValue = '123';   
    #   ga('set', 'metric1', metricValue);
    #
    #   Lifetime Spend
    #   var metricValue = '123';
    #   ga('set', 'metric2', metricValue);
    #   
    #   Original Cohort - scope user
    #   var dimensionValue = 'SOME_DIMENSION_VALUE';
    #   ga('set', 'dimension1', dimensionValue);
    #   
    #   Maker - scope hit    
    #   var dimensionValue = 'SOME_DIMENSION_VALUE';
    #   ga('set', 'dimension2', dimensionValue);
    #
    #   Payment Method
    #   var dimensionValue = 'SOME_DIMENSION_VALUE';
    #   ga('set', 'dimension3', dimensionValue);

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
        cd1: original_cohort(o.email),
        cm1: latency(o.email),
        cm2: lifetime_spend(o),
        cd3: payment_method(o)
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
        cu:  li.order.currency,
        cd2: maker(li.variant)
      }
    end

    def ga_adjustment_details(ad, cid)
      order = ad.source
      {
        cid: cid,
        ti:  order.number,
        in:  ad.label,
        ip:  ad.amount.to_f,
        iq:  1,
#        ic:  name(ad),
        iv:  ad.originator_type,
        cu:  order.currency
      }
    end


    def maker(variant)
      variant.product.gang_member.name
    end

    def name(adjustment)
      if adjustment.kind_of?(Spree::Promotion::Actions::CreateAdjustment)
        adjustment.originator.promotion.description
      else
        adjustment.originator.name
      end
    end

    def original_cohort(email)
      category(Spree::Order.complete.where(email: email).reorder('completed_at ASC').first)
    end

    def latency(email)
      last_two_orders = Spree::Order.complete.where(email: email).reorder('completed_at DESC').pluck(:completed_at)[0,2]
      return 0 if last_two_orders.size < 2
      ## latency in numbers of days
      ((((last_two_orders[0] - last_two_orders[1])/ 60) / 60) / 24).floor
    end

    def lifetime_spend(o)
      o.payment_total.to_f
    end

    def payment_method(o)
      o.payments.where(state: :completed).last.source_type
    end
  end
end
