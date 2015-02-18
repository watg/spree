module Spree
  class ShipmentMailer < BaseMailer
    def shipped_email(shipment, resend = false)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Store.current.name} #{Spree.t('shipment_mailer.shipped_email.subject')} ##{@shipment.order.number}"
      mail(to: @shipment.order.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "shipment", template: "#{I18n.locale}_shipped_metapack_email")
      headers['X-MC-MergeVars'] = shipment_data.to_json
    end

    def survey_email(order)
      order_number = order.number
      name = order.bill_address.full_name
      email = order.email
      subject = "Order Number #{order_number}, How did we do?"
      mail(to: email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "order survey", template: "#{I18n.locale}_survey_email")
      headers['X-MC-MergeVars'] = {
          order_number: order_number,
          email: email,
          name: name
        }.to_json
    end

    private
    def shipment_data
      {
        manifest: htmlify(:manifest),
        tracking_details: htmlify(:tracking)
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


    def tracking_template
      t=<<EOF
<% @shipment.order.parcels.each_with_index do |parcel, index| %>
<tr><td>Parcel <%= index + 1 %> - <%= parcel.metapack_tracking_url %></td></tr>
<% end %>
EOF
      t
    end
  end
end
