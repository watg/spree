module Spree
  class BaseMailer < ActionMailer::Base

    def from_address
      Spree::Config[:mails_from]
    end

    def money(amount, currency = Spree::Config[:currency])
      Spree::Money.new(amount, currency: currency).to_s
    end
    def mandrill_default_headers(opts={})
      defaults = {
        'X-MC-Track'           => "opens, clicks_all",
        'X-MC-GoogleAnalytics' => "woolandthegang.com",
        'X-MC-Tags'            => opts[:tags],
        'X-MC-Autotext'        => "on",
        'X-MC-InlineCSS'       => "true",
        'X-MC-Template'        => opts[:template]
      }

      defaults.each do |key, value|
        headers[key] = value 
      end
    end

    def htmlify(key)
      template = send("#{key}_template".to_sym)
      ERB.new(template).result(binding)
    end

    helper_method :money

    def mail(headers={}, &block)
      super if Spree::Config[:send_core_emails]
    end

  end
end
