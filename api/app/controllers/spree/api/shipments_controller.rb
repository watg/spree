module Spree
  module Api
    class ShipmentsController < Spree::Api::BaseController

      before_action :find_and_update_shipment, only: [:ship, :ready, :add, :remove, :add_by_line_item, :remove_by_line_item]
      before_action :load_transfer_params, only: [:transfer_to_location, :transfer_to_shipment]

      def mine
        if current_api_user.persisted?
          @shipments = Spree::Shipment
            .reverse_chronological
            .joins(:order)
            .where(spree_orders: {user_id: current_api_user.id})
            .includes(mine_includes)
            .ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
        else
          render "spree/api/errors/unauthorized", status: :unauthorized
        end
      end

      def create
        @order = Spree::Order.find_by!(number: params.fetch(:shipment).fetch(:order_id))
        authorize! :read, @order
        authorize! :create, Shipment
        quantity = params[:quantity].to_i
        @shipment = @order.shipments.create(stock_location_id: params.fetch(:stock_location_id))
        @order.contents.add(variant, quantity, options)

        @shipment.save!
        respond_with(@shipment.reload, default_template: :show)
      end

      def update
        @shipment = Spree::Shipment.accessible_by(current_ability, :update).readonly(false).find_by!(number: params[:id])
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

      def add
        quantity = params[:quantity].to_i

        @shipment.order.contents.add(variant, quantity, options)

        respond_with(@shipment, default_template: :show)
      end

      def add_by_line_item
        quantity = params[:quantity].to_i
        returned_line_item = @shipment.order.contents.add_by_line_item(line_item, quantity, { shipment: @shipment})
        if returned_line_item.errors.any?
          invalid_resource!(returned_line_item)
        else
          respond_with(@shipment, default_template: :show)
        end
      end

      def remove
        quantity = params[:quantity].to_i
        @shipment.order.contents.remove(variant, quantity, options)
        @shipment.reload if @shipment.persisted?
        respond_with(@shipment, default_template: :show)
      end
      
      def remove_by_line_item
        quantity = params[:quantity].to_i
        returned_line_item = @shipment.order.contents.remove_by_line_item(line_item, quantity, { shipment: @shipment})
        if returned_line_item.errors.any?
          invalid_resource!(returned_line_item)
        else
          @shipment.reload if @shipment.persisted?
          respond_with(@shipment, default_template: :show)
        end
      end

      def transfer_to_location
        @stock_location = Spree::StockLocation.find(params[:stock_location_id])
        @original_shipment.transfer_to_location(@variant, @quantity, @stock_location)
        render json: {success: true, message: Spree.t(:shipment_transfer_success)}, status: 201
      end

      def transfer_to_shipment
        @target_shipment  = Spree::Shipment.find_by!(number: params[:target_shipment_number])
        @original_shipment.transfer_to_shipment(@variant, @quantity, @target_shipment)
        render json: {success: true, message: Spree.t(:shipment_transfer_success)}, status: 201
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

      def line_item
        @line_item ||= Spree::LineItem.find(params[:line_item_id])
      end

      def options_parser
        @options_parser ||= Spree::LineItemOptionsParser.new(@shipment.order.currency)
      end

      def find_order
        if params[:order_id].present?
          ActiveSupport::Deprecation.warn "Spree::Api::ShipmentsController#find_order is deprecated and will be removed from Spree 2.3.x, access shipments directly without being nested to orders route instead.", caller
          @order = Spree::Order.find_by!(number: params[:order_id])
          authorize! :read, @order
        end
      end

      def load_transfer_params
        @original_shipment         = Spree::Shipment.where(number: params[:original_shipment_number]).first
        @variant                   = Spree::Variant.find(params[:variant_id])
        @quantity                  = params[:quantity].to_i
        authorize! :read, @original_shipment
        authorize! :create, Shipment
      end

      def find_and_update_shipment
        @shipment = Spree::Shipment.accessible_by(current_ability, :update).readonly(false).find_by!(number: params[:id])
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

      def variant
        @variant ||= Spree::Variant.unscoped.find(params.fetch(:variant_id))
      end

      def mine_includes
        {
          order: {
            bill_address: {
              state: {},
              country: {},
            },
            ship_address: {
              state: {},
              country: {},
            },
            adjustments: {},
            payments: {
              order: {},
              payment_method: {},
            },
          },
          inventory_units: {
            line_item: {
              product: {},
              variant: {},
            },
            variant: {
              product: {},
              default_price: {},
              option_values: {
                option_type: {},
              },
            },
          },
        }
      end
    end
  end
end
