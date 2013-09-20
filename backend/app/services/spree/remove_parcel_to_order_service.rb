module Spree
  class RemoveParcelToOrderService < Mutations::Command

    required do
      integer :box_id
      integer :quantity
      integer :order_id
    end
    
    def execute
      verify_quantity(quantity)
      order, box = load_models(order_id, box_id)

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
      add_error(:quantity, :quantity_cannot_be_negative, "Quantity cannot be negative") if quantity < 0
    end
  end
end
