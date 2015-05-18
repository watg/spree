module Spree
  class ListSalesReport
    include BaseReport

    attr_accessor :completed_orders, :first_order_checker

    def initialize(params)
      @option_types = generate_option_types 
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])
      @completed_orders = ::Report::Query::CompletedOrders.new(order_types: %w(regular party))
      @first_order_checker = ::Report::Domain::FirstOrderChecker.new(@completed_orders)
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
      completed_orders.query.where(:completed_at => @from..@to ).find_each do |o|
        o.line_items.each do |li|

          # A hack incase someone deletes the variant or product
          variant = Variant.unscoped.find(li.variant_id)

          shipped_at = ''
          if !o.shipments.last.shipped_at.blank? 
            shipped_at = o.shipments.last.shipped_at.to_s(:db)
          end

          yield csv_array( li, o, shipped_at, variant, li.quantity)

          li.line_item_parts.required.each do |p|
            yield csv_array( li, o, shipped_at, p.variant, p.quantity * li.quantity, 'required_part' )
          end

          li.line_item_parts.optional.each do |p|
            yield csv_array( li, o, shipped_at, p.variant, p.quantity * li.quantity, 'optional_part' )
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

    def csv_array(li, o, shipped_at, variant, quantity, part_type='')
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
        !first_order_checker.first_order?(o),
        o.email,
      ] + option_types_for_variant(variant) + adjustments(o)
    end

  end
end
