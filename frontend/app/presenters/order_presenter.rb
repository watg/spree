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
      shipping_method_duration = shipment.shipping_method.shipping_method_duration
      shipping_method_duration.extend(ShippingMethodDurations::Description)
      shipping_method_duration.dynamic_description
    end.join("<br/>")
  end

  def shipping_method_durations
    order.shipments.map(&:shipping_method).shipping_method_duration
  end

  def total_label
    order.shipments.any? ? Spree.t(:total) : Spree.t(:subtotal)
  end

  def adjustments_excluding_shipping_and_tax
    eligible_adjustments.without_shipping_rate.without_tax.adjustments
  end

  private

  def all_adjustments
    Adjustments::Selector.new(order.all_adjustments)
  end

  def eligible_adjustments
    eligible_adjustments ||= all_adjustments.eligible
  end
end
