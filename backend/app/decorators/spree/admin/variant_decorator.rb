module Spree
  module Admin
    class VariantDecorator < Draper::Decorator
      decorates 'Spree::Variant'
      delegate_all

      def number_of_shipment_pending(supplier=nil)
        pending =  Spree::InventoryUnit.where(variant_id: object.id, state: :on_hand, pending: false).joins(:order).where('spree_orders.state in (?)', %w{resumed complete})
        supplier_id = supplier ? supplier.id : nil
        pending = pending.where(supplier_id: supplier_id)
        pending.count
      end

    end
  end
end
