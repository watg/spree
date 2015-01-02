module Spree
  module Api
    class ShipmentsController < Spree::Api::BaseController

      before_filter :find_order
      before_filter :find_and_update_shipment, only: [:ship, :ready, :add, :remove, :add_by_line_item, :remove_by_line_item]

      def create
        # TODO Can remove conditional here once deprecated #find_order is removed.
        unless @order.present?
          @order = Spree::Order.find_by!(number: params[:shipment][:order_id])
          authorize! :read, @order
        end
        authorize! :create, Shipment
        quantity = params[:quantity].to_i
        @shipment = @order.shipments.create(stock_location_id: params[:stock_location_id])
# ASD: add options
        @order.contents.add(variant, quantity, nil, @shipment)

        @shipment.save!
        respond_with(@shipment.reload, default_template: :show)
      end

      def update
        if @order.present?
          @shipment = @order.shipments.accessible_by(current_ability, :update).find_by!(number: params[:id])
        else
          @shipment = Spree::Shipment.accessible_by(current_ability, :update).readonly(false).find_by!(number: params[:id])
        end

        @shipment.update_attributes_and_order(shipment_params)
        respond_with(@shipment.reload, default_template: :show)
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

#ASD: add options
      def add
        quantity = params[:quantity].to_i

        @shipment.order.contents.add(variant, quantity, nil, @shipment)

        respond_with(@shipment, default_template: :show)
      end

      def add_by_line_item
        quantity = params[:quantity].to_i
        returned_line_item = @order.contents.add_by_line_item(line_item, quantity, @shipment)
        if returned_line_item.errors.any?
          invalid_resource!(returned_line_item)
        else
          respond_with(@shipment, default_template: :show)
        end
      end

      def remove
        quantity = params[:quantity].to_i
#ASD: add options
        @shipment.order.contents.remove(variant, quantity, @shipment)
        @shipment.reload if @shipment.persisted?
        respond_with(@shipment, default_template: :show)
      end
      
#ASD: add options
      def remove_by_line_item
        quantity = params[:quantity].to_i
        returned_line_item = @order.contents.remove_by_line_item(line_item, quantity, @shipment)
        if returned_line_item.errors.any?
          invalid_resource!(returned_line_item)
        else
          @shipment.reload if @shipment.persisted?
          respond_with(@shipment, default_template: :show)
        end
      end

      private

      def options
        # Below is a hack to deal with old kits as well as new
        parts = []
        if selected_variants = params.delete(:selected_variants)
          parts = options_parser.dynamic_kit_parts(variant, selected_variants)
        else
          parts = options_parser.static_kit_required_parts(variant)
        end
        {
          shipment: @shipment,
          parts: parts
        }
      end

      def variant
        @variant ||= Spree::Variant.find(params[:variant_id])
      end

      def line_item
        @line_item ||= Spree::LineItem.find(params[:line_item_id])
      end

      def options_parser
        @options_parser ||= Spree::LineItemOptionsParser.new(@order.currency)
      end

      def find_order
        if params[:order_id].present?
          ActiveSupport::Deprecation.warn "Spree::Api::ShipmentsController#find_order is deprecated and will be removed from Spree 2.3.x, access shipments directly without being nested to orders route instead.", caller
          @order = Spree::Order.find_by!(number: params[:order_id])
          authorize! :read, @order
        end
      end

      def find_and_update_shipment
        if @order.present?
          @shipment = @order.shipments.accessible_by(current_ability, :update).find_by!(number: params[:id])
        else
          @shipment = Spree::Shipment.accessible_by(current_ability, :update).readonly(false).find_by!(number: params[:id])
        end
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
