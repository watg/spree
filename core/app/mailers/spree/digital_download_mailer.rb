module Spree
  class DigitalDownloadMailer < BaseMailer
    def send_links(order)
      mandrill_default_headers(
        tags: "order, downloads",
        template: "#{I18n.locale}_digital_downloads"
      )
      headers['X-MC-MergeLanguage'] = "handlebars"
      headers['X-MC-MergeVars'] = merge_vars(order).to_json

      subject = "#{Spree::Config[:site_name]} #{Spree.t('digital_download_mailer.send_links.subject')} ##{order.number}"
      mail(to: order.email, from: from_address, subject: subject, body: "")
    end

    private

    def merge_vars(order)
      {
        downloads: downloads(order),
        multiple:  order.digital_links.size > 1,
      }
    end

    def downloads(order)
      order.digital_links.map do |link|
        {
          name: link.name,
          url:  link.url,
        }
      end
    end
  end
end
