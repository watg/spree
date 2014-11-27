module Spree
  class FeederRequirementMailerJob
    def perform
      subject = "Stock movement required"

      message = ""
      plan = Spree::FeederRequirement.new.plan
      plan.each_pair do |location, feed_requirement|
        feed_requirement.each do |feeder, variants|
          message << "#{feeder.name} -> #{location.name}\n"
          variants.each do |variant, count|
            message << "  #{count} of #{variant.sku}\n"
          end
          message << "\n"
        end
      end

      if plan.present?
        mailer = Spree::NotificationMailer.send_notification(message, email_list, subject)
        mailer.deliver
      end
    end

    private

    def email_list
      Rails.application.config.feeder_requirements_email_list
    end
  end
end
