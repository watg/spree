module Spree
  module Admin
    class GeneralSettingsController < Spree::Admin::BaseController
      # end of multi currency
      def edit
        @preferences_general = [:site_name, :default_seo_title, :default_meta_keywords,
                        :default_meta_description, :site_url]
        @preferences_security = [:allow_ssl_in_production,
                        :allow_ssl_in_staging, :allow_ssl_in_development_and_test,
                        :check_for_spree_alerts]
        @preferences_currency = [:display_currency, :hide_cents, :allow_currency_change, :show_currency_selector, :supported_currencies]
      end

      def update
        params.each do |name, value|
          next unless Spree::Config.has_preference? name
          # from multi currency extensio
          if name == "supported_currencies"
            value = value.split(',').map { |curr| ::Money::Currency.find(curr.strip).try(:iso_code) }.concat([Spree::Config[:currency]]).uniq.compact.join(',')
          end
          # end of multi currency 
          Spree::Config[name] = value
        end
        flash[:success] = Spree.t(:successfully_updated, :resource => Spree.t(:general_settings))

        redirect_to edit_admin_general_settings_path
      end

      def dismiss_alert
        if request.xhr? and params[:alert_id]
          dismissed = Spree::Config[:dismissed_spree_alerts] || ''
          Spree::Config.set :dismissed_spree_alerts => dismissed.split(',').push(params[:alert_id]).join(',')
          filter_dismissed_alerts
          render :nothing => true
        end
      end
    end
  end
end
