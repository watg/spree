module Spree
  class ShipmentMailer < BaseMailer
    def shipped_email(shipment, resend = false)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Config[:site_name]} #{Spree.t('shipment_mailer.shipped_email.subject')} ##{@shipment.order.number}"
      mail(to: @shipment.order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "shipment", template: "#{I18n.locale}_shipped_email")
      headers['X-MC-MergeVars'] = shipment_data.to_json
    end

    private
    def shipment_data
      {
        manifest: htmlify(:manifest),
        tracking: @shipment.tracking,
        tracking_url: @shipment.tracking_url
      }
    end
    
    def manifest_template
      t=<<EOF
<% @shipment.manifest.each do |item| %>
<tr><td><%= item.variant.product.name %>: <%= item.variant.options_text %></td></tr>
<% end %>
EOF
      t
    end
    
  end
end
