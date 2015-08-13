module Spree
  class OrderFormatter
    using ShippingMethodDurations::Description

    EMPTY_CELL   = %|-----------|
    DEFAULT_FONT = %|normal|

    def initialize(order)
      @order = order
    end

    def order_data
      {
        order_number: @order.number,
        email: @order.email,
        items: line_items,
        items_total: items_total.to_html,
        shipment_total: shipment_total.to_html,
        adjustments: taxes,
        promotions: promotions,
        adjustments_total: adjustments_total.to_html,
        delivery_time: delivery_time,
        currency: @order.currency,
        payment_total: order_total.to_html,
        digital_message: digital_message
      }
    end

    private

    def delivery_time
      if @order.shipments.any? && @order.shipments.first.shipping_method.present?
        @order.shipments.first.shipping_method.shipping_method_duration.dynamic_description
      end
    end

    def shipment_coster
      ::Shipping::Coster.new(@order.shipments)
    end

    def adjustments_selector
      ::Adjustments::Selector.new(@order.all_adjustments)
    end

    def shipment_total
      format_money shipment_coster.final_price
    end

    def items_total
      format_money @order.item_total
    end

    def adjustments_total
      format_money @order.adjustment_total + shipment_coster.adjustment_total
    end

    def order_total
      format_money @order.total
    end

    def promotions
      adjustments = adjustments_selector.promotion.eligible.without_shipping_rate.group_by(&:label)
      adjustments_template(adjustments)
    end

    def taxes
      taxes = adjustments_selector.tax.additional.eligible.group_by(&:label)
      adjustments_template(taxes)
    end

    def format_money(amount)
      Spree::Money.new(amount, { currency: @order.currency })
    end

    def adjustments_template(adjustments)
      template = ''
      adjustments.each do |label, adjustment|
        next if adjustment.sum(&:amount) == 0
        template += '<tr>' +
          '<td colspan=3 style="font-family:\'Helvetica Neue\', Helvetica, Arial, sans-serif; font-size:12px; border-top: dotted 1px; padding: 10px;" >' +
          label +
          '</td>' +
          '<td style="font-family:\'Helvetica Neue\', Helvetica, Arial, sans-serif; font-size:12px; border-top: dotted 1px; padding: 10px;" >' +
          format_money(adjustment.sum(&:amount)).to_html +
          '</td>' +
          '</tr>'
      end
      template.to_s
    end

    def line_items
      @order.line_items.map do |li|
        build_table_row(li, li.quantity) + build_parts_table_rows(li)
      end.join.to_s
    end

    def build_parts_table_rows(line_item)
      return "" unless line_item.product.normal?

      line_item.parts.map do |part|
        build_table_row(part, part.quantity * line_item.quantity, EMPTY_CELL, DEFAULT_FONT)
      end.join.to_s
    end

    def build_table_row(item, quantity, amount = nil, font_weight = "bold")
      ["<tr>",
       "<td align='left' style='font-weight:#{font_weight};'>%s</td>" % item.product.name.to_s,
       "<td align='left'>%s</td>" % quantity.to_s,
       "<td align='left'>%s</td>" % item.variant.options_text.to_s,
       "<td align='left'>%s</td>" % (amount || item.display_amount.to_s),
       "</tr>"
      ].join
    end

    def digital_message
      if @order.digital?
        "Your PDF pattern will be sent in a separate email, it should be with you in 5-10 minutes from receiving this order confirmation."
      else
        ""
      end
    end
  end
end
