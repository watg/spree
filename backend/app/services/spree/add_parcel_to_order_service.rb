module Spree
  class AddParcelToOrderService < ActiveInteraction::Base

    integer :box_id
    integer :quantity
    integer :order_id

    def execute
      return unless verify_quantity(quantity)
      order, box = load_models(order_id, box_id)
      return unless is_addition_allowed?(order)
      
      quantity.times { Spree::Parcel.create!(parcel_attrs(box).merge(order_id: order.id)) }
      reduce_stock_for(box, quantity)
    rescue Exception => error
      errors.add(:parcel, error.inspect)
    end

    private
    def load_models(o_id, b_id)
      [Spree::Order.find(o_id), Spree::Product.find(b_id)]
    end

    def parcel_attrs(box)
      {
        weight: box.weight,
        height: box.height,
        width:  box.width,
        depth:  box.depth,
        box_id: box.id
      }
    end

    def reduce_stock_for(product, qtty)
      stock_item = product.master.stock_items[0]
      stock_item.adjust_count_on_hand((-1 * qtty))
    end

    def verify_quantity(quantity)
      if quantity < 0
        errors.add(:quantity, "Quantity cannot be negative")
        return false
      end
      true
    end

    def is_addition_allowed?(order)
      if order.metapack_allocated
        errors.add(:allocated, "Cannot add parcels to allocated order")
        return false
      end
      true
    end
  end
end
