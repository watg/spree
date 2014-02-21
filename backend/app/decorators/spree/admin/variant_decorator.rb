module Spree
  module Admin
    class VariantDecorator < Draper::Decorator
      decorates 'Spree::Variant'
      delegate_all

      def number_of_shipment_pending
        Spree::InventoryUnit.where(variant_id: object.id, state: :on_hand, pending: false).joins(:order).where('spree_orders.state in (?)', %w{resumed complete}).count
      end

    end
  end
end
