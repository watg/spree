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
    
    #   First Order Date
    #   var dimensionValue = 'SOME_DIMENSION_VALUE';
    #   ga('set', 'dimension4', dimensionValue);

    attr_reader :params, :user_id
    def initialize(params={})
      @params = params
      @user_id = params[:user_id]
    end

    def perform
      Rails.logger.info("GA_BUG Performing for: #{@user_id}")
      send(event)
    end

    def transaction
      # TODO: track: - sales discount
      # TODO: track: - b2b/affiliates discount [JL, ]
      # TODO: product collection [TS x watg, tartan, ...]
      if params[:order].completed_at
        Rails.logger.info("GA_BUG I have a completed_at")
        GA.transaction(ga_transaction_details(params[:order], user_id))
        Rails.logger.info("GA_BUG line items: #{params[:order].line_items.count}")
        Rails.logger.info("GA_BUG adjustments: #{params[:order].adjustments.count}")
        params[:order].line_items.each  {|i| GA.item(ga_item_details(i, user_id))}
        params[:order].adjustments.each {|i| GA.item(ga_adjustment_details(i, user_id))}
      end
    end

    def no_event_error
      raise "SUPPORTED event names: [transaction]"
    end

    private
    def event
      Rails.logger.info("GA_BUG has we an event: #{@event}")
      return @event if @event
      _e = params[:event].downcase.to_sym rescue :no_event_error
      @event = ( [:transaction, :no_event_error].include?(_e) ? _e : :no_event_error)
    end

    def ga_transaction_details(o, cid)
      {
        cid: cid,
        ti: o.number,
        tr: o.total.to_f,
        tt: o.display_tax_total.to_f,
        ts: o.shipments.last.cost.to_f,
        cu: o.currency,
        cd1: original_cohort(o.email),
        cm1: latency(o.email),
        cm2: lifetime_spend(o),
        cd3: payment_method(o),
        cm4: customer_first_order_date(o.email)
      }
    end

    def ga_item_details(li, cid)
      {
        cid: cid,
        ti:  li.order.number,
        in:  li.variant.name,
        ip:  li.price.to_f,
        iq:  li.quantity,
        ic:  li.item_sku,
        iv:  li.variant.product.marketing_type.name,
        cu:  li.order.currency,
        #cd2: maker(li.variant)
      }
    end

    def ga_adjustment_details(ad, cid)
      {
        cid: cid,
        ti:  ad.order.number,
        in:  ad.label,
        ip:  ad.amount.to_f,
        iq:  1,
#        ic:  name(ad),
        iv:  ad.source_type,
        cu:  ad.order.currency
      }
    end

    #def maker(variant)
    #  variant.product.supplier.name
    #end

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
      last_payment = o.payments.where(state: :completed).last
      last_payment.source_type if last_payment
    end

    def customer_first_order_date(email)
      o = Spree::Order.complete.where(email: email).reorder('completed_at ASC').first
      o.completed_at rescue nil
    end
  end
end
