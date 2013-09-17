module Spree
  class OrderSummaryReport
    include BaseReport

    HEADER = %w(
  id
  email
  order_number
  item_quantity
  completed_at
  shipped_at
  location_shipped
  returning_customer
  currency
  revenue_pre_sale_pre_ship_pre_promo 
  revenue_pre_ship_pre_promo
  revenue_shipping_pre_promo
  promos
  revenue_received
  kit_revenue_pre_promo
  virtual_product_pre_promo
  gang_collection_revenue_pre_promo
  r2w_revenue_pre_promo
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

    def initialize(params)
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])  
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])  
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      HEADER
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
          option_costs = li.line_item_options.inject(0) { |acc,val| acc + ( val.price * val.quantity ).to_f }
          product_type_totals[ variant.product_type ] += option_costs 
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
      if !o.shipment.shipped_at.blank? 
        shipped_at = o.shipment.shipped_at.to_s(:db)
      end

      # If the first order they have ever made is equal to this one, then we 
      # can assume they are a new customer 
      returning_customer = false
      if o.user
        if o.user.orders.size > 1 and o != o.user.orders.order("id").first
          returning_customer = true
        elsif previous_users.include? o.user.email.to_s
          returning_customer = true
        end
      end

      payment_method = ''
      if payment = o.payments.find_by_state('completed')
        payment_method = payment.payment_method.name
      end

      shipping_methods = o.shipment.shipping_methods

      [
        o.id, 
        o.email,
        o.number, 
        o.line_items.size,
        o.completed_at.to_s(:db), 
        shipped_at,
        o.shipping_address.country.name,
        returning_customer,
        o.currency,
        o.item_normal_total.to_f,
        o.item_total.to_f, # Total cost
        o.ship_total,
        o.promo_total,
        o.total.to_f, # Over cost
        product_type_totals['kit'] || '',
        product_type_totals['virtual_product'] || '',
        product_type_totals['gang_collection'] || '',
        product_type_totals['ready_to_wear'] || '',
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
        ( shipping_methods.find_by_display_on('front_end') ? shipping_methods.find_by_display_on('front_end').name : '' ),
        ( shipping_methods.find_by_display_on('back_end') ? shipping_methods.find_by_display_on('back_end').name : '' ),
      ] 

    end
    
  end
end
