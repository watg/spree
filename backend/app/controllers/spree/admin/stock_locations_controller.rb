module Spree
  module Admin
    class StockLocationsController < ResourceController

      before_filter :set_country, :only => :new
      before_filter :load_existing_active_locations, :only => [:new, :create, :edit, :update]

      private

      def set_country
        begin
          if Spree::Config[:default_country_id].present?
            @stock_location.country = Spree::Country.find(Spree::Config[:default_country_id])
          else
            @stock_location.country = Spree::Country.find_by!(iso: 'US')
          end

        rescue ActiveRecord::RecordNotFound
          flash[:error] = Spree.t(:stock_locations_need_a_default_country)
          redirect_to admin_stock_locations_path and return
        end
      end

      def load_existing_active_locations
        @existing_active_locations = ::Spree::StockLocation.valid_feed_into_locations_for(@stock_location)
      end

    end
  end
end
