module Spree
  class BulkOrderPrintingService < Mutations::Command

    def execute
      orders = Spree::Order.unprinted_invoices
      print_date = Time.now
      last_batch_id = Spree::Order.last_batch_id_today
      orders.each_with_index do |order, idx|
        order.batch_print_id = last_batch_id + idx + 1
        order.batch_invoice_print_date = print_date
        order.save!
      end

      Spree::PDF::OrdersToBeDispatched.orders_to_pdf(orders)
    end

  end
end
