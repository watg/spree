module Spree
  class OrderSummary < Spree::ExportedDataCsv

    FILENAME = 'order_summary_'

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
  revenue_pre_ship_pre_discount
  revenue_shipping_pre_discount
  discounts
  revenue_received
  kit_revenue_pre_discount
  virtual_product_pre_discount
  gang_collection_revenue_pre_discount
  r2w_revenue_pre_discount
  supplies_revenue_pre_discount

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

    protected

    def header
      HEADER
    end
    
    def filename
      FILENAME
    end

    def retrieve_data( params )
      #Spree::Order.complete.where( :completed_at => params[:from]..params[:to] ).each do |o| 
      Spree::Order.complete.all.each do |o| 
        yield data(o)
      end
    end

    def generate_product_type_totals( o )
      product_type_totals = Hash.new 
      o.line_items.each do |li| 
        cost = li.price.to_f * li.quantity
        if ['kit','virtual_product'].include? li.variant.product_type 
          product_type_totals[ li.variant.product_type ] ||= 0 
          product_type_totals[ li.variant.product_type ] += cost 
          # Add the optional parts
          option_costs = li.line_item_options.inject(0) { |acc,val| acc + ( val.price * val.quantity ).to_f }
          product_type_totals[ li.variant.product_type ] += option_costs 
        else
          if li.variant.product.gang_member.nickname != 'WATG'
            product_type_totals['gang_collection'] ||= 0 
            product_type_totals['gang_collection'] += cost
          else
            if li.variant.isa_part?
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

    def data(o)
      product_type_totals = generate_product_type_totals(o)
      shipment_costs = o.shipments.inject(0) {|acc,val| acc + val.cost.to_f } # Total cost including shipment
      adjustment_costs = o.adjustments.inject(0) {|acc,val| acc + val.amount.to_f } - shipment_costs  # Total adjustments including shipping

      shipped_at = ''
      if !o.shipment.shipped_at.blank? 
        shipped_at = o.shipment.shipped_at.to_s(:db)
      end

      # If the first order they have ever made is equal to this one, then we 
      # can assume they are a new customer 
      returning_customer = false
      if o.user and o.user.orders.size > 1 and o != o.user.orders.order("id").first
        returning_customer = true
      end

      payment_method = ''
      if payment = o.payments.find_by_state('completed')
        payment_method = payment.payment_method.name
      end

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
        o.item_total.to_f, # Total cost
        shipment_costs,
        adjustment_costs,
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

        o.shipment.shipping_methods.find_by_display_on('front_end').name,
        o.shipment.shipping_methods.find_by_display_on('back_end').name,
      ] 
    end

  end
end
