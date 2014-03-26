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
        currency
        cost_price 
        revenue_pre_sale_pre_ship_pre_promo 
        revenue_pre_ship_pre_promo
        revenue_shipping_pre_promo
        promos
        promo_code
        revenue_received
        kit_revenue_pre_promo
        virtual_product_pre_promo
        gang_collection_revenue_pre_promo
        r2w_revenue_pre_promo
        patterns_revenue_pre_promo
        supplies_revenue_pre_promo

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

      Spree::Order.where( :state => 'complete', :completed_at => @from..@to ).each do |o| 
        yield generate_csv_line(o,previous_users)
      end
    end

    private

    def generate_product_type_totals( o )
      product_type_totals = Hash.new 
      o.line_items.each do |li| 

        # A hack incase someone deletes the variant or product
        variant = Variant.unscoped.find(li.variant_id)

        cost = li.price.to_f * li.quantity
        if ['kit','virtual_product'].include? variant.product_type 
          product_type_totals[ variant.product_type ] ||= 0 
          product_type_totals[ variant.product_type ] += cost 
          # Add the optional parts
          option_costs = li.line_item_parts.optional.inject(0) { |acc,val| acc + ( val.price * val.quantity ).to_f }
          product_type_totals[ variant.product_type ] += option_costs 
        elsif variant.product_type == 'pattern'
          product_type_totals['pattern'] ||= 0 
          product_type_totals['pattern'] += cost
        else
          if variant.sku.match(/^GANG-/)
            product_type_totals['gang_collection'] ||= 0 
            product_type_totals['gang_collection'] += cost
          else
            if variant.isa_part?
              product_type_totals['part'] ||= 0 
              product_type_totals['part'] += cost 
            else
              product_type_totals['ready_to_wear'] ||= 0 
              product_type_totals['ready_to_wear'] += cost
            end
          end

        end

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

      first_eligible_promotion = o.adjustments.promotion.eligible.first
      promo_label = first_eligible_promotion.label if first_eligible_promotion
      [
        o.id, 
        o.email,
        o.number, 
        o.line_items.size,
        o.completed_at.to_s(:db), 
        shipped_at,
        o.shipping_address.country.name,
        returning_customer(o,previous_users),
        o.currency,
        o.cost_price_total.to_f,
        o.item_normal_total.to_f,
        o.item_total.to_f, # Total cost
        o.ship_total,
        o.promo_total,
        promo_label,
        o.total.to_f, # Over cost
        product_type_totals['kit'] || '',
        product_type_totals['virtual_product'] || '',
        product_type_totals['gang_collection'] || '',
        product_type_totals['ready_to_wear'] || '',
        product_type_totals['pattern'] || '',
        product_type_totals['part'] || '',

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
