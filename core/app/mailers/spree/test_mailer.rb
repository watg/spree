module Spree
  class TestMailer < BaseMailer
    def test_email(user)
      subject = "#{Spree::Config[:site_name]} #{Spree.t('test_mailer.test_email.subject')}"
      recipient = user.respond_to?(:id) ? user : Spree.user_class.find(user)
      mail(to: recipient.email, from: from_address, subject: subject)

      mandrill_default_headers(tags: "test", template: "#{I18n.locale}_test_email")
      headers['X-MC-MergeVars'] = data.to_json
    end

    private
    def data
      {
        line_items: "<ul id=\"line_items\"><li>this is a line items</li><li>aaaaaaaaaaaaa (323.33)</li><li>item (3.40)</li><li>s test (3.22)</li></ul>"
      }
    end
  end
end
