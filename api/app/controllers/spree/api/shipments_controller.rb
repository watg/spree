module Spree
  module Api
    class ShipmentsController < Spree::Api::BaseController

      before_filter :find_order
      before_filter :find_and_update_shipment, only: [:ship, :ready, :add, :remove, :add_by_line_item, :remove_by_line_item]

      def create
        authorize! :create, Shipment
        quantity = params[:quantity].to_i
        @shipment = @order.shipments.create(stock_location_id: params[:stock_location_id])
        @order.contents.add(variant, quantity, nil, @shipment, options_with_qty)

        @shipment.refresh_rates
        @shipment.save!

        respond_with(@shipment.reload, default_template: :show)
      end

      def update
        @shipment = @order.shipments.accessible_by(current_ability, :update).find_by!(number: params[:id])

        unlock = params[:shipment].delete(:unlock)

        if unlock == 'yes'
          @shipment.adjustment.open
        end

        @shipment.update_attributes(shipment_params)

        if unlock == 'yes'
          @shipment.adjustment.close
        end

        @shipment.reload
        respond_with(@shipment, default_template: :show)
      end

      def ready
        unless @shipment.ready?
          if @shipment.can_ready?
            @shipment.ready!
          else
            render 'spree/api/shipments/cannot_ready_shipment', status: 422 and return
          end
        end
        respond_with(@shipment, default_template: :show)
      end

      def ship
        unless @shipment.shipped?
          @shipment.ship!
        end
        respond_with(@shipment, default_template: :show)
      end

      def add
        quantity = params[:quantity].to_i
        @order.contents.add(variant, quantity, @order.currency, @shipment, options_with_qty)
        respond_with(@shipment, default_template: :show)
      end

      def add_by_line_item
        quantity = params[:quantity].to_i
        @order.contents.add_by_line_item(line_item, quantity, @shipment)
        respond_with(@shipment, default_template: :show)
      end

      def remove
        quantity = params[:quantity].to_i
        @order.contents.remove(variant, quantity, @shipment)
        @shipment.reload if @shipment.persisted?
        respond_with(@shipment, default_template: :show)
      end

      def remove_by_line_item
        quantity = params[:quantity].to_i
        @order.contents.remove_by_line_item(line_item, quantity, @shipment)
        @shipment.reload if @shipment.persisted?
        respond_with(@shipment, default_template: :show)
      end

      private
      def options_with_qty
        Spree::OrderPopulator.parse_options(variant, params[:selected_variants] || [], @order.currency)
      end

      def variant
        @variant ||= Spree::Variant.find(params[:variant_id])
      end

      def line_item
        @line_item ||= Spree::LineItem.find(params[:line_item_id])
      end

      def find_order
        @order = Spree::Order.find_by!(number: params[:order_id])
        authorize! :read, @order
      end

      def find_and_update_shipment
        @shipment = @order.shipments.accessible_by(current_ability, :update).find_by!(number: params[:id])
        @shipment.update_attributes(shipment_params)
        @shipment.reload
      end

      def shipment_params
        if params[:shipment] && !params[:shipment].empty?
          params.require(:shipment).permit(permitted_shipment_attributes)
        else
          {}
        end
      end
    end
  end
end
