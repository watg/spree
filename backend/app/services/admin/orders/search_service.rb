module Admin
  module Orders
    # search service that filters the orders using ransack
    class SearchService < ActiveInteraction::Base
      hash :params,
           strip: false
      interface :current_ability
      SearchResponse = Struct.new(:search_object, :show_only_completed)

      def execute
        set_defaults_params
        @search_params = params[:q].deep_dup
        convert_search_params
        search = Spree::Order.accessible_by(current_ability, :index).ransack(@search_params)
        SearchResponse.new(search, show_only_completed_orders?)
      end

      private

      def set_defaults_params
        show_only_complete_orders_by_default = Spree::Config[:show_only_complete_orders_by_default]
        params[:q][:completed_at_not_null] ||= "1" if show_only_complete_orders_by_default
      end

      def convert_search_params
        @search_params[:s] ||= show_only_completed_orders? ? "completed_at desc" : "created_at desc"
        @search_params[:express] = @search_params[:filter_express] == "1"
        if params[:q][:inventory_units_shipment_id_null] == "0"
          @search_params.delete(:inventory_units_shipment_id_null)
        end
        convert_range_to_complete_at if show_only_completed_orders?
        parse_search_range(:created_at_gt)
        parse_search_range(:completed_at_lt)
      end

      def show_only_completed_orders?
        @search_params[:completed_at_not_null] == "1"
      end

      def convert_range_to_complete_at
        @search_params[:completed_at_gt] = @search_params.delete(:created_at_gt)
        @search_params[:completed_at_lt] = @search_params.delete(:created_at_lt)
      end

      def parse_search_range(key)
        return unless @search_params[key].present?
        @search_params[key] = Time.zone.parse(@search_params[key]).try(:beginning_of_day)
      end
    end
  end
end
