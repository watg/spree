module Spree
  class GiftCardMailer < BaseMailer
    def issuance_email(gift_card, resend = false)
      order = gift_card.buyer_order
      @card = gift_card
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "Nice one - a WOOL AND THE GANG Gift Card for you"
      mail(to: order.email, from: from_address, subject: subject)

      tag = (resend ? 'issuance' : 're-issuance')
      mandrill_default_headers(tags: "gift_card, #{tag}", template: "#{I18n.locale}_gift_card_issuance_email")
      headers['X-MC-MergeVars'] = issuance_data(gift_card).to_json
    end

    private
    def issuance_data(c)
      {
        order_number: c.buyer_order.number,
        email:        c.buyer_order.email,
        amount:  Spree::Money.new(c.value, currency: c.currency).to_html,
        code:         c.code,
        expiry_date:  c.expiry_date
      }
    end
  end
end
