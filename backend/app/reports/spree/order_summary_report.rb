# Report which returns a summary of completed orders
module Spree
  class OrderSummaryReport
    include BaseReport

    attr_accessor :completed_orders, :first_order_checker

    def initialize(params)
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])
      @completed_orders = ::Report::Query::CompletedOrders.new( order_types: %w(regular party)).query
      @first_order_checker = ::Report::Domain::FirstOrderChecker.new(@completed_orders)
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      %w(
        id
        email
        order_number
        item_quantity
        completed_at
        shipped_at
        location_shipped
        returning_customer
        internal
        order_type
        currency
        cost_price
        item_normal_total
        item_total
        shipping_total
        additional_tax
        shipping_promo
        promo_total
        gift_card_total
        manual_adjustments_total
        promo_code
        payment_total
        order_total
      ) + marketing_type_headers + %w(
        billing_address_firstname
        billing_address_lastname
        billing_address_line_1
        billing_address_line_2
        billing_city
        billing_country
        billing_postcode

        shipping_address_firstname
        shipping_address_lastname
        shipping_address_line_1
        shipping_address_line_2
        shipping_city
        shipping_country
        shipping_postcode

        payment_successes
        payment_type

        shipping_method_frontend
        shipping_method_backend
        state
        latest_note
        important
      )
    end

    def retrieve_data
      loop_orders do |order|
        yield generate_csv_line(order)
      end
    end

    def marketing_type_headers
      marketing_type_lookup.map { |mt| "#{mt}_revenue_pre_promo" }
    end

    def marketing_type_totals(o)
      totals = o.line_items.each_with_object({}) do |line, h|
        # A hack incase someone deletes the variant or product
        variant = Variant.unscoped.find(line.variant_id)

        marketing_type = variant.product.marketing_type.name

        h[marketing_type] ||= 0
        h[marketing_type] += line.amount

        options_amount = line.line_item_parts.optional.inject(0) do |acc, val|
          acc + (val.price * val.quantity).to_f
        end
        h[marketing_type] += options_amount
      end

      marketing_type_lookup.map { |mt| totals[mt] || 0.0 }
    end

    private

    def loop_orders
      completed_orders.includes(:shipments, line_items: [:line_item_parts])
        .where(completed_at: @from..@to).find_each do |order|
        yield order
      end
    end

    def marketing_type_lookup
      Spree::MarketingType.all.map(&:name)
    end

    def generate_csv_line(o)
      shipped_at = ""
      unless o.shipments.last.nil?
        unless o.shipments.last.shipped_at.blank?
          shipped_at = o.shipments.last.shipped_at.to_s(:db)
        end
      end

      payment_method = ""
      if payment = o.payments.find_by_state('completed')
        unless payment.payment_method.nil?
          payment_method = payment.payment_method.name
        end
      end

      unless o.shipments.last.nil?
        shipping_methods = o.shipments.last.shipping_methods
      end

      promotions = Spree::Adjustment.promotion.where(order_id: o.id, state: :closed, eligible: true)
      promo_label = promotions.map(&:label).join("|")
      # Are we sure we are meant to be doing this?
      return unless promo_label
      [
        o.id,
        o.email,
        o.number,
        o.line_items.size,
        o.completed_at.try(:to_s, :db),
        shipped_at,
        o.shipping_address.country.name,
        !first_order_checker.first_order?(o),
        o.internal?,
        o.order_type.title,
        o.currency,
        o.cost_price_total.to_f,
        o.item_normal_total.to_f,
        o.item_total.to_f, # Total cost
        o.ship_total,
        o.additional_tax_total,
        o.shipments.to_a.sum(&:promo_total).to_f,
        o.promo_total,
        o.adjustments.gift_card.sum(:amount).to_f,
        o.adjustments.manual.sum(:amount).to_f,
        promo_label,
        o.payment_total.to_f, # Over cost
        o.total.to_f # Over cost

      ] + marketing_type_totals(o) + [

        o.billing_address.firstname,
        o.billing_address.lastname,
        o.billing_address.address1,
        o.billing_address.address2,
        o.billing_address.city,
        o.billing_address.country.name,
        o.billing_address.zipcode,

        o.shipping_address.firstname,
        o.shipping_address.lastname,
        o.shipping_address.address1,
        o.shipping_address.address2,
        o.shipping_address.city,
        o.shipping_address.country.name,
        o.shipping_address.zipcode,

        o.payments.where(state: %w(completed, pending)).size,
        payment_method,
        frontend_shipping_method(shipping_methods),
        backend_shipping_method(shipping_methods),
        o.state,
        o.order_notes.last ? o.order_notes.last.reason : "",
        o.important?
      ]
    end

    def frontend_shipping_method(shipping_methods)
      if shipping_methods && shipping_methods.find_by_display_on("front_end")
        shipping_methods.find_by_display_on("front_end").name
      else
        ""
      end
    end

    def backend_shipping_method(shipping_methods)
      if shipping_methods && shipping_methods.find_by_display_on("back_end")
        shipping_methods.find_by_display_on("back_end").name
      else
        ""
      end
    end

  end
end
