module Spree
  class OrderFormatter
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
        delivery_time: @order.delivery_time || 'soon',
        currency: @order.currency,
        payment_total: order_total.to_html,
        digital_message: digital_message
      }
    end

    private

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
      template.to_html
    end

    def line_items
      t = ''
      @order.line_items.map do |line_item|
        t += '<tr>' +
          '<td align="left" style="font-weight:bold;">' +
          line_item.product.name.to_s +
          '</td>' +
          '<td align="left">' +
          line_item.quantity.to_s +
          '</td><td align="left">' +
          line_item.variant.options_text.to_s +
          '</td><td align="left">' +
          line_item.display_amount.to_s +
          '</td>' +
          '</tr>'
      end
      t.to_s
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
