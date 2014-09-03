module Spree
  class GangSalesReport
    include BaseReport

    HEADER = %w(
  order_id
  number
  line_item_id
  supplier_firstname
  supplier_lastname
  supplier_nickname
  supplier_company_name
  supplier_is_company
  created_at
  shipped_at
  completed_at
  product_sku
  variant_sku
  product_name
  marketing_type
  state
  quantity
  currency

  item_revenue_pre_sale
  item_revenue

  order_revenue_pre_sale_pre_ship_pre_promo
  order_revenue_pre_ship_pre_promo
  order_revenue_shipping_pre_promo
  order_promos
  order_revenue_received

  email
    ) unless defined?(HEADER)

    def initialize(params)
      @option_types = generate_option_types
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      header = HEADER + @option_types.map { |ot| ot[0] }
      header
    end

    def retrieve_data
      completed_line_items( @from, @to ).find_each do |li|

        grouped_inventory_units(li).each do |unit|

          # A hack incase someone deletes the variant or product
          variant = Variant.unscoped.find(unit[:variant])
          supplier = unit[:supplier]
          quantity = unit[:quantity]
          order = li.order

          if variant.sku.match(/^GANG-/)

            shipped_at = ''
            if !order.shipments.last.shipped_at.blank?
              shipped_at = order.shipments.last.shipped_at.to_s(:db)
            end

            yield csv_array( li, supplier, quantity, order, variant, shipped_at )

          end
        end
      end
    end

    private

    def grouped_inventory_units(line)
      grouped = line.inventory_units.group_by do |iu|
        [ Spree::Variant.unscoped.find_by_id(iu.variant_id), iu.supplier]
      end
      grouped.map do |k,v|
        variant = k[0]
        supplier = k[1]
        is_part = ( variant == line.variant )? false : true
        { variant: variant, supplier: supplier, quantity: v.count, is_part: is_part }
      end
    end

    def completed_line_items(from, to)
      Spree::LineItem.all.merge(
        Spree::Order.complete.where(:completed_at => from..to)
      ).references(:order).includes(:order, :variant, inventory_units: [:supplier] )
    end

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

    def csv_array(li, supplier, quantity, o, variant, shipped_at)
      [
        o.id,
        o.number,
        li.id,
        supplier.firstname,
        supplier.lastname,
        supplier.nickname,
        supplier.company_name,
        supplier.is_company,
        o.created_at.to_s(:db),
        shipped_at,
        o.completed_at.to_s(:db),
        variant.product.sku,
        variant.sku,
        variant.product.name,
        variant.product.marketing_type.name,
        o.state,
        quantity,
        li.currency,
        li.normal_price || li.price,
        li.price,

        o.item_normal_total.to_f,
        o.item_total.to_f, # Total cost
        o.ship_total,
        o.promo_total,
        o.total.to_f, # Over cost

        o.email,
      ] + option_types_for_variant(variant) + adjustments(o)

    end

  end
end
