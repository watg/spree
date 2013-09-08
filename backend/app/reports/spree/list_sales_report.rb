module Spree
  class ListSalesReport

    HEADER = %w(
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
  product_type
  quantity
  state
  email
    )

    def initialize(params)
      @option_types = generate_option_types 
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])  
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])  
    end

    def header
      header = HEADER + @option_types.map { |ot| ot[0] }
      header = header + %w( promo1 promo2 promo3 promo4 ) 
      header
    end

    def retrieve_data

      Spree::Order.where( :state => 'complete', :completed_at => @from..@to ).each do |o| 
        o.line_items.each do |li|

          shipped_at = ''
          if !o.shipment.shipped_at.blank? 
            shipped_at = o.shipment.shipped_at.to_s(:db)
          end

          yield csv_array( li, o, shipped_at, li.variant, li.quantity )

          if li.product.product_type == 'kit' or li.product.product_type == 'virtual_product'

            li.variant.required_parts_for_display.each do |p|
              yield  csv_array( li, o, shipped_at, p, p.count_part, 'required_part' )
            end
            li.line_item_options.each do |p|
              yield csv_array( li, o, shipped_at, p.variant, p.quantity, 'optional_part' )
            end

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
      o.adjustments.eligible.map do |adjustment|
        next if ((adjustment.originator_type == 'Spree::TaxRate') and (adjustment.amount == 0)) || adjustment.originator_type == 'Spree::ShippingMethod'
        adjustment.label
      end
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
        variant.sku,
        variant.product.name,
        variant.product.product_type,
        quantity,
        o.state,
        o.email,
      ] + option_types_for_variant(li.variant) + adjustments(o)
    end

  end
end
