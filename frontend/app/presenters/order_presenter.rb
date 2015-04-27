# Presenter for Order on the front end
class OrderPresenter < Spree::BasePresenter
  presents :order

  def has_step?(step)
    order.has_step?(step)
  end


  def display_shipments
    order.shipments.map do |shipment|
      "#{shipment.stock_location.name} : #{shipment.shipping_method.try(:name)}"
    end.join("<br/>")
  end

  def display_delivery_time
    order.shipments.map do |shipment|
      "#{shipment.shipping_method.shipping_method_duration.description}"
    end.join("<br/>")
  end

  def total_label
    order.shipments.any? ? Spree.t(:total) : Spree.t(:subtotal)
  end
end
