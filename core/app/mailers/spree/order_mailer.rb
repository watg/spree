module Spree
  class OrderMailer < BaseMailer
    def confirm_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Config[:site_name]} #{Spree.t('order_mailer.confirm_email.subject')} ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "order, confirmation", template: "#{I18n.locale}_confirm_email")
      headers['X-MC-MergeVars'] = confirm_data.to_json
    end

    def cancel_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Config[:site_name]} #{Spree.t('order_mailer.cancel_email.subject')} ##{@order.number}"
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
        email: @order.user.email,
        items: htmlify(:line_items),
        items_total: @order.item_total.to_s,
        adjustments: htmlify(:adjustements),
        adjustments_total: @order.adjustment_total.to_s,
        currency: @order.currency,
        payment_total: @order.payment_total.to_s
      }
    end

    def adjustements_template
      t =<<EOF
<ul class="adjustments">
<% @order.adjustments.eligible.each do |adjustment| %>
<% next if (adjustment.originator_type == 'Spree::TaxRate') and (adjustment.amount == 0) %>
<li><span class="adjustment-label"><%= adjustment.label %>: </span><span class="adjustment-amount"><%= adjustment.display_amount.to_html %></span></li>
<% end %>
</ul>
EOF
      t
    end

    def line_items_template
      t =<<EOF
<% @order.line_items.map do |line_item| %>
<% has_kit_options = !line_item.line_item_options.blank? %>
<h4><%= line_item.product.name %></h4>
<ul class="line-items">
<% if has_kit_options %>
<li>(1 * <%= line_item.variant.price_in(@order.currency) %>) <%= line_item.variant.options_text %></li>
<% line_item.line_item_options.each do |o| %>
<li>(<%= o.quantity %> * <%= o.variant.kit_price_in(@order.currency) %>) <%= o.variant.name %></li>
<% end %>
<% else %><li><%= line_item.variant.options_text %></li><% end %>
</ul><% end %>
EOF
      t
    end
    
  end
end
