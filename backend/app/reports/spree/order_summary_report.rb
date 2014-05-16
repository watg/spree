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
        kit_revenue_pre_promo
        peruvian_product_pre_promo
        gang_collection_revenue_pre_promo
        yarn_revenue_pre_promo
        patterns_revenue_pre_promo
        needles_revenue_pre_promo

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
      )
    end

    def retrieve_data

      # This is from the old system
      previous_users = CSV.read(File.join(File.dirname(__FILE__),"unique_previous_users.csv")).flatten
      previous_users = previous_users.to_set

      Spree::Order.includes(:shipments).where( :state => 'complete', :completed_at => @from..@to ).find_each do |o| 
        yield generate_csv_line(o,previous_users)
      end
    end

    private

    def generate_product_type_totals( o )
      product_type_totals = Hash.new 
      
      o.line_items.each do |line| 
        # A hack incase someone deletes the variant or product
        variant = Variant.unscoped.find(line.variant_id)

        marketing_type = variant.product.marketing_type
        product_type_totals[marketing_type.name] ||= 0
        product_type_totals[marketing_type.name] += line.amount 
      end

      product_type_totals
    end



    def generate_csv_line(o,previous_users)
      product_type_totals = generate_product_type_totals(o)

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
        o.total.to_f, # Over cost
        product_type_totals['kit'] || '',
        product_type_totals['peruvian'] || '',
        product_type_totals['gang'] || '',
        product_type_totals['yarn'] || '',
        product_type_totals['pattern'] || '',
        product_type_totals['needle'] || '',

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

        o.payments.where( :state => ['completed','pending']).size,
        payment_method,
        ( shipping_methods && shipping_methods.find_by_display_on('front_end') ? shipping_methods.find_by_display_on('front_end').name : '' ), 
        ( shipping_methods && shipping_methods.find_by_display_on('back_end') ? shipping_methods.find_by_display_on('back_end').name : '' ),
      ] 
      end

    end

    private

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
      user ? user.orders.complete : orders_by_email(email)
    end

    def orders_by_email(email)
      Spree::Order.where(email: email).complete
    end
    
  end
end
