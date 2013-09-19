module Spree
  class AddParcelToOrderService < Mutations::Command

    required do
      integer :box_id
      integer :quantity
      integer :order_id
    end
    
    def execute
      verify_quantity(quantity)
      order, box = load_models(order_id, box_id)

      quantity.times { Spree::Parcel.create!(box_id: box.id, order_id: order.id) }
    rescue Exception => error
      add_error(:parcel, :parcel_error, error)
    end

    private
    def load_models(o_id, b_id)
      [Spree::Order.find(o_id), Spree::Product.find(b_id)]
    end

    def verify_quantity(quantity)
      add_error(:quantity, :quantity_cannot_be_negative, "Quantity cannot be negative") if quantity < 0
    end
  end
end
