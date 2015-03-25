module Admin
  module Orders
    # Enables or disables the sending of post-shipment emails on an order.
    class ShipmentEmailController < Spree::Admin::BaseController
      def create
        order = find_order
        Admin::Orders::UpdateShipmentEmailOnOrder.run!(order: order, state: true)

        respond_to do |format|
          format.html { redirect_to admin_waiting_orders_url }
          format.js do
            render partial: 'spree/admin/waiting_orders/shipment_email',
                   locals: { order: order }
          end
        end
      end

      def destroy
        order = find_order
        Admin::Orders::UpdateShipmentEmailOnOrder.run!(order: order, state: false)

        respond_to do |format|
          format.html { redirect_to admin_waiting_orders_url }
          format.js do
            render partial: 'spree/admin/waiting_orders/shipment_email',
                   locals: { order: order }
          end
        end
      end

      private

      def find_order
        Spree::Order.find_by(number: params[:order_id])
      end
    end
  end
end
