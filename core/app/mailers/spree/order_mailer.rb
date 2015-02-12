module Spree
  class OrderMailer < BaseMailer
    def confirm_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Store.current.name} #{Spree.t('order_mailer.confirm_email.subject')} ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "order, confirmation", template: "#{I18n.locale}_confirm_email")
      headers['X-MC-MergeVars'] = confirm_data.to_json
    end

    def cancel_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Store.current.name} #{Spree.t('order_mailer.cancel_email.subject')} ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "order, cancellation", template: "#{I18n.locale}_cancel_email")
      headers['X-MC-MergeVars'] = cancel_data.to_json
    end

    private
    def cancel_data
      order_data.merge({})
    end

    def confirm_data
      order_data.merge({})
    end

    def order_data
      {
          order_number: @order.number,
          email: @order.email,
          items: htmlify(:line_items),
          items_total: items_total.to_html,
          shipment_total: shipment_total.to_html,
          adjustments: htmlify(:taxes),
          promotions: htmlify(:promotions),
          adjustments_total: adjustments_total.to_html,
          delivery_time: @order.delivery_time,
          currency: @order.currency,
          payment_total: order_total.to_html
      }
    end

    def shipment_total
      format_money @order.shipment_total
    end

    def items_total
      format_money @order.item_total
    end

    def adjustments_total
      format_money @order.adjustment_total
    end

    def order_total
      format_money @order.total
    end


    def promotions_template
      adjustments_template(@order.all_adjustments.promotion.eligible.group_by(&:label))
    end

    def taxes_template
      adjustments_template( @order.all_adjustments.tax.eligible.group_by(&:label))
    end

    def format_money(amount)
      Spree::Money.new(amount, { currency: @order.currency })
    end

    def adjustments_template(adjustments)
      template=''
      adjustments.each do |label, adjustments|
        next if adjustments.sum(&:amount) == 0
        template+='<tr>'+
            '<td colspan=3 style="font-family:\'Helvetica Neue\', Helvetica, Arial, sans-serif; font-size:12px; border-top: dotted 1px; padding: 10px;" >'+
            label+
            '</td>'+
            '<td style="font-family:\'Helvetica Neue\', Helvetica, Arial, sans-serif; font-size:12px; border-top: dotted 1px; padding: 10px;" >'+
            format_money(adjustments.sum(&:amount)).to_html +
            '</td>'+
            '</tr>'
      end
      template
    end

    def line_items_template

      t =<<EOF
<% @order.line_items.map do |line_item| %>
<tr>
<td align="left" style="font-weight:bold;"><%= line_item.product.name %></td>
<td align="left"><%= line_item.quantity %></td><td align="left"><%= line_item.variant.options_text %></td><td align="left"><%= line_item.display_amount.to_s %></td>
</tr>
<% end %>
EOF
      t
    end

  end
end
