class OrderShipmentEmailPresenter < Spree::BasePresenter
  presents :order

  def send_email?
    order.shipments.map(&:send_email?).uniq == [true]
  end
end
