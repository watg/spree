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
        items_total: @order.item_total.to_s,
        shipment_total: @order.shipment_total.to_s,
        adjustments: htmlify(:adjustements),
        adjustments_total: @order.adjustment_total.to_s,
        currency: @order.currency,
        payment_total: @order.total.to_s
      }
    end

    def adjustements_template
      t =<<EOF
<% @order.adjustments.eligible.each do |adjustment| %>
<% next if (adjustment.source_type == 'Spree::TaxRate') and (adjustment.amount == 0) %>
<tr>
<td><%= adjustment.label %>: <%= adjustment.display_amount.to_html %></td>
</tr>
<% end %>
EOF
      t
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
