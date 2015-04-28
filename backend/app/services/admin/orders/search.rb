module Admin
  module Orders
    class Search < ActiveInteraction::Base
      hash :params,
           strip: false
      interface :current_ability

      def execute
        params[:q] ||= {}
        params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
        @show_only_completed = params[:q][:completed_at_not_null] == '1'
        params[:q][:s] ||= @show_only_completed ? 'completed_at desc' : 'created_at desc'

        # As date params are deleted if @show_only_completed, store
        # the original date so we can restore them into the params
        # after the search
        created_at_gt = params[:q][:created_at_gt]
        created_at_lt = params[:q][:created_at_lt]

        params[:q].delete(:inventory_units_shipment_id_null) if params[:q][:inventory_units_shipment_id_null] == "0"

        if params[:q][:created_at_gt].present?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if params[:q][:created_at_lt].present?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if @show_only_completed
          params[:q][:completed_at_gt] = params[:q].delete(:created_at_gt)
          params[:q][:completed_at_lt] = params[:q].delete(:created_at_lt)
        end

        @search = orders.accessible_by(current_ability, :index).ransack(params[:q])

        # Restore dates
        params[:q][:created_at_gt] = created_at_gt
        params[:q][:created_at_lt] = created_at_lt
        @search
      end

      private

      def orders
        Spree::Order.select("spree_orders.*, true = any(
                      select express from
                      spree_shipping_methods
                      inner join spree_shipping_rates on spree_shipping_rates.shipping_method_id = spree_shipping_methods.id
                      inner join spree_shipments on spree_shipping_rates.shipment_id = spree_shipments.id
                      where spree_shipments.order_id = spree_orders.id
                      ) as express")
      end
    end
  end
end
