module Spree
  class GangSalesReport
    include BaseReport

    HEADER = %w(
  order_id
  number
  line_item_id
  gang_member_firstname
  gang_member_lastname
  gang_member_nickname
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

      Spree::Order.where( :state => 'complete', :completed_at => @from..@to ).each do |o| 
        o.line_items.each do |li|

          # A hack incase someone deletes the variant or product
          variant = Variant.unscoped.find(li.variant_id)

          if variant.sku.match(/^GANG-/)

            shipped_at = ''
            if !o.shipments.last.shipped_at.blank? 
              shipped_at = o.shipments.last.shipped_at.to_s(:db)
            end

            yield csv_array( li, o, variant, shipped_at )

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

    def csv_array(li, o, variant, shipped_at)
      [
        o.id, 
        o.number, 
        li.id, 
        variant.product.gang_member.firstname,
        variant.product.gang_member.lastname,
        variant.product.gang_member.nickname,
        o.created_at.to_s(:db),
        shipped_at,
        o.completed_at.to_s(:db), 
        variant.product.sku,
        variant.sku,
        variant.product.name,
        variant.product.marketing_type.name,
        o.state,
        li.quantity,
        li.currency,
        li.normal_price || li.price,
        li.price,

        o.item_normal_total.to_f,
        o.item_total.to_f, # Total cost
        o.ship_total,
        o.promo_total,
        o.total.to_f, # Over cost

        o.email,
      ] + option_types_for_variant(li.variant) + adjustments(o)

    end

  end
end
