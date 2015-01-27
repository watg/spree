module Spree
  class ListSalesReport
    include BaseReport

    def initialize(params)
      @option_types = generate_option_types 
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])  
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])  
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      header = %w(
        order_id
        number
        line_item_id
        created_at
        shipped_at
        completed_at
        part_type
        product_sku
        variant_sku
        product_name
        marketing_type
        quantity
        state
        payment_method
        returning_customer
        email
      )
      header = header + @option_types.map { |ot| ot[0] }
      header = header + %w( promo1 promo2 promo3 promo4 ) 
      header
    end

    def retrieve_data
      # This is from the old system
      previous_users = CSV.read(File.join(File.dirname(__FILE__),"unique_previous_users.csv")).flatten
      previous_users = previous_users.to_set

      Spree::Order.where( :state => 'complete', :completed_at => @from..@to ).each do |o| 
        o.line_items.each do |li|

          # A hack incase someone deletes the variant or product
          variant = Variant.unscoped.find(li.variant_id)

          shipped_at = ''
          if !o.shipments.last.shipped_at.blank? 
            shipped_at = o.shipments.last.shipped_at.to_s(:db)
          end

          yield csv_array( li, o, shipped_at, variant, li.quantity, previous_users )

          li.line_item_parts.required.each do |p|
            yield csv_array( li, o, shipped_at, p.variant, p.quantity * li.quantity, 'required_part', previous_users )
          end

          li.line_item_parts.optional.each do |p|
            yield csv_array( li, o, shipped_at, p.variant, p.quantity * li.quantity, 'optional_part', previous_users )
          end

        end
      end
    end

    private
    def generate_option_types
      Spree::OptionType.all.map do |ot|
        [ ot.name, ot.id ]
      end
    end

    def adjustments(o)
      promotions = Spree::Adjustment.promotion.where(order_id: o.id, state: :closed, eligible: true)
      promotions.map(&:label)
    end

    def option_types_for_variant(variant)
      @option_types.map do |ot|
        id = ot[1]
        ov = variant.option_values.find_by_option_type_id(id)
        if ov
          ov.name
        else
          '' 
        end
      end
    end

    def csv_array(li, o, shipped_at, variant, quantity, part_type='', previous_users)
      [
        o.id, 
        o.number, 
        li.id, 
        o.created_at.to_s(:db),
        shipped_at,
        o.completed_at.to_s(:db), 
        part_type,
        variant.product.sku,
        li.item_sku,
        variant.product.name,
        variant.product.marketing_type.name,
        quantity,
        o.state,
        (o.payments.first.source_type.split('::').last if o.payments.first.try(:source_type)),
        returning_customer(o,previous_users),
        o.email,
      ] + option_types_for_variant(variant) + adjustments(o)
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
      user ? user.orders.complete : orders_by_email(email)
    end

    def orders_by_email(email)
      Spree::Order.where(email: email).complete
    end


  end
end
