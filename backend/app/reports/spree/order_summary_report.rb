module Spree
  class OrderSummaryReport
    include BaseReport

    def initialize(params)
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])
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
        currency
        cost_price
        item_normal_total
        item_total
        shipping_total
        additional_tax
        shipping_promo
        promo_total
        gift_card_total
        promo_code
        payment_total
        order_total
      ) +
        marketing_type_headers +
      %w(
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
      # This is from the old system
      previous_users = CSV.read(File.join(File.dirname(__FILE__),"unique_previous_users.csv")).flatten
      previous_users = previous_users.to_set

      loop_orders do |order|
        yield generate_csv_line(order, previous_users)
      end
    end

    def marketing_type_headers
      marketing_type_lookup.map { |mt| "#{mt}_revenue_pre_promo" }
    end

    def marketing_type_totals( o )

      totals = o.line_items.inject({}) do |h,line|

        # A hack incase someone deletes the variant or product
        variant = Variant.unscoped.find(line.variant_id)

        marketing_type = variant.product.marketing_type.name

        h[marketing_type] ||= 0
        h[marketing_type] += line.amount

        options_amount = line.line_item_parts.optional.inject(0) { |acc,val| acc + ( val.price * val.quantity ).to_f }

        h[marketing_type] += options_amount

        h
      end

      marketing_type_lookup.map { |mt| totals[mt] || 0.0 }
    end

  private

    def loop_orders(&block)
      valid_states = %w(complete resumed warehouse_on_hold customer_service_on_hold)

      Spree::Order.includes(:shipments, line_items: [ :line_item_parts] ).
          where( :state => valid_states, :completed_at => @from..@to ).find_each do |order|

        yield order
      end
    end



    def marketing_type_lookup
      Spree::MarketingType.all.map(&:name)
    end

    def generate_csv_line(o,previous_users)

      shipped_at = ''
      if !o.shipments.last.nil?
        if !o.shipments.last.shipped_at.blank?
          shipped_at = o.shipments.last.shipped_at.to_s(:db)
        end
      end

      payment_method = ''
      if payment = o.payments.find_by_state('completed')
        if !payment.payment_method.nil?
          payment_method = payment.payment_method.name
        end
      end

      if !o.shipments.last.nil?
        shipping_methods = o.shipments.last.shipping_methods
      end

      promotions = Spree::Adjustment.promotion.where(order_id: o.id, state: :closed, eligible: true)
      promo_label = promotions.map(&:label).join('|')
      if promo_label
      [
        o.id,
        o.email,
        o.number,
        o.line_items.size,
        o.completed_at.to_s(:db),
        shipped_at,
        o.shipping_address.country.name,
        returning_customer(o,previous_users),
        o.internal?,
        o.currency,
        o.cost_price_total.to_f,
        o.item_normal_total.to_f,
        o.item_total.to_f, # Total cost
        o.ship_total,
        o.additional_tax_total,
        o.shipments.sum(:promo_total).to_f,
        o.promo_total,
        o.adjustments.gift_card.sum(:amount).to_f,
        promo_label,
        o.payment_total.to_f, # Over cost
        o.total.to_f ] + # Over cost

        marketing_type_totals(o) +

        [ o.billing_address.firstname,
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

        o.payments.where( :state => ['completed','pending']).size,
        payment_method,
        ( shipping_methods && shipping_methods.find_by_display_on('front_end') ? shipping_methods.find_by_display_on('front_end').name : '' ),
        ( shipping_methods && shipping_methods.find_by_display_on('back_end') ? shipping_methods.find_by_display_on('back_end').name : '' ),
        o.state,
        o.order_notes.last ? o.order_notes.last.reason : "",
        o.important?,
      ]
      end

    end


    def returning_customer(order,previous_users)
      rtn = !first_order(order)
      if rtn == false
        if previous_users.include? order.email.to_s
          rtn = true
        end
      end
      rtn
    end

    def first_order(order)
      if order.user || order.email
        orders_complete = completed_orders(order.user, order.email)
        orders_complete.blank? || (orders_complete.order("completed_at asc").first == order)
      else
        false
      end
    end

    def completed_orders(user, email)
      if user
        Spree::Order.where("email = ? or user_id = ?", email, user.id).complete
      else
        Spree::Order.where("email = ?", email).complete
      end
    end

  end
end
