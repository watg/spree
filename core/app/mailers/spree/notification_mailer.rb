module Spree
  class NotificationMailer < BaseMailer
    default from: "TechWATG <techadmin@woolandthegang.com>"

    def send_notification(message, to=nil, subject=nil)
      to ||= 'techadmin@woolandthegang.com'
      subject ||= 'Notification from the site'
      @message = message
      mail(:to => to, :subject => subject)

      mandrill_default_headers(template: "admin_notifications")
      headers['X-MC-MergeVars'] = { message: message }.to_json
    end

  end
end
