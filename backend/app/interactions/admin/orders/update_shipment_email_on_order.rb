module Admin
  module Orders
    class UpdateShipmentEmailOnOrder < ActiveInteraction::Base
      model :order, class: Spree::Order
      boolean :state

      def execute
        order.shipments.each do |s|
          s.update_attributes(send_email: state)
        end
      end
    end
  end
end
