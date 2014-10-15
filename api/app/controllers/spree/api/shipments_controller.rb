module Spree
  module Api
    class ShipmentsController < Spree::Api::BaseController

      before_filter :find_order
      before_filter :find_and_update_shipment, only: [:ship, :ready, :add, :remove, :add_by_line_item, :remove_by_line_item]

      def create
        authorize! :create, Shipment
        quantity = params[:quantity].to_i
        @shipment = @order.shipments.create(stock_location_id: params[:stock_location_id])
        @order.contents.add(variant, quantity, options)
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
        returned_line_item = @order.contents.add(variant, quantity, options)
        if returned_line_item.errors.any?
          invalid_resource!(returned_line_item)
        else
          respond_with(@shipment, default_template: :show)
        end
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
        returned_line_item = @order.contents.remove(variant, quantity, options)
        if returned_line_item.errors.any?
          invalid_resource!(returned_line_item)
        else
          @shipment.reload if @shipment.persisted?
          respond_with(@shipment, default_template: :show)
        end
      end

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
        @order = Spree::Order.find_by!(number: order_id)
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
