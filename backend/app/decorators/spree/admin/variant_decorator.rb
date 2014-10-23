module Spree
  module Admin
    class VariantDecorator < Draper::Decorator
      decorates 'Spree::Variant'
      delegate_all

      def number_of_shipment_pending(item)
        pending =  Spree::InventoryUnit.where(variant_id: object.id, state: :on_hand, pending: false).
          joins(:order, :shipment).where('spree_orders.state in (?)', %w{resumed complete}).
          where('spree_shipments.stock_location_id = ?', item.stock_location_id)
        supplier_id = item.supplier ? item.supplier.id : nil
        pending = pending.where(supplier_id: supplier_id)
        pending.count
      end

    end
  end
end
