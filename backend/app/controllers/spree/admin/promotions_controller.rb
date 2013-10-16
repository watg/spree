module Spree
  module Admin
    class PromotionsController < ResourceController
      before_filter :load_data
      before_filter :load_event_names

      helper 'spree/promotion_rules'

      protected
        def location_after_save
          spree.edit_admin_promotion_url(@promotion)
        end

        def load_data
          @calculators = Rails.application.config.spree.calculators.promotion_actions_create_adjustments
        end


        def load_event_names
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          Rails.logger.info("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC")
          @event_names = Spree::Activator.event_names.map { |name| [Spree.t("events.#{name}"), name] }
          Rails.logger.info("aslkjalskdjalskdjalksjdlkasjd")
          Rails.logger.info("aslkjalskdjalskdjalksjdlkasjd")
          Rails.logger.info("aslkjalskdjalskdjalksjdlkasjd")
          Rails.logger.info("aslkjalskdjalskdjalksjdlkasjd")
          Rails.logger.info("aslkjalskdjalskdjalksjdlkasjd")
        end
    end
  end
end
