module Spree
  class RemoveParcelToOrderService < Mutations::Command

    required do
      integer :box_id
      integer :quantity
      integer :order_id
    end
    
    def execute
      return unless verify_quantity(quantity)
      order, box = load_models(order_id, box_id)
      return unless is_allowed?(order)
      
      Spree::Parcel.destroy(order.parcels.map(&:id))
      add_stock_for(box, quantity)
    rescue Exception => error
      add_error(:parcel, :parcel_error, error)
    end

    private
    def load_models(o_id, b_id)
      [Spree::Order.find(o_id), Spree::Product.find(b_id)]
    end

    def add_stock_for(product, qtty)
      stock_item = product.master.stock_items[0]
      stock_item.adjust_count_on_hand(qtty)
    end

    def verify_quantity(quantity)
      if quantity < 0
        add_error(:quantity, :quantity_cannot_be_negative, "Quantity cannot be negative")
        return false
      end
      true
    end

    def is_allowed?(order)
      if order.metapack_allocated
        add_error(:allocated, :cannot_remove_parcel_from_allocated_order, "Cannot remove parcels from allocated order")
        return false
      end
      true
    end
  end
end
