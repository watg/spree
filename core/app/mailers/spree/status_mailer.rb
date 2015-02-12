module Spree
  class StatusMailer < BaseMailer
    def order_data(order)
      {
        order_number: order.number,
        email: order.email,
        items: line_items(order),
        items_total: items_total(order).to_html,
        shipment_total: shipment_total(order).to_html,
        adjustments: taxes(order),
        promotions: promotions(order),
        adjustments_total: adjustments_total(order).to_html,
        delivery_time: order.delivery_time,
        currency: order.currency,
        payment_total: order_total(order).to_html,
      }
    end

    private

    def shipment_total(order)
      format_money order.shipment_total, order
    end

    def items_total(order)
      format_money order.item_total, order
    end

    def adjustments_total(order)
      format_money order.adjustment_total, order
    end

    def order_total(order)
      format_money order.total, order
    end


    def promotions(order)
      promotions = order.all_adjustments.promotion.eligible.group_by(&:label)
      adjustments_template(promotions, order)
    end

    def taxes(order)
      taxes = order.all_adjustments.tax.additional.eligible.group_by(&:label)
      adjustments_template(taxes, order)
    end

    def format_money(amount, order)
      Spree::Money.new(amount, { currency: order.currency })
    end

    def adjustments_template(adjustments, order)
      template = ''
      adjustments.each do |label, adjustment|
        next if adjustment.sum(&:amount) == 0
        template += '<tr>' +
          '<td colspan=3 style="font-family:\'Helvetica Neue\', Helvetica, Arial, sans-serif; font-size:12px; border-top: dotted 1px; padding: 10px;" >' +
          label +
          '</td>' +
          '<td style="font-family:\'Helvetica Neue\', Helvetica, Arial, sans-serif; font-size:12px; border-top: dotted 1px; padding: 10px;" >' +
          format_money(adjustment.sum(&:amount), order).to_html +
          '</td>' +
          '</tr>'
      end
      template.to_html
    end

    def line_items(order)
      t = ''
      order.line_items.map do |line_item|
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
  end
end
