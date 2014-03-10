module Spree
  module PDF
    class OrdersToBeDispatched
      class << self
        def create_orders(pdf, orders)
          orders.each do |order|
            index = order.batch_print_id
            number_of_invoices(order).times {
              pdf = CommercialInvoice.new(order, pdf).create(index)
              pdf.start_new_page
            }
          end

          pdf
        end

        def create_stickers(pdf, orders)
          orders.each do |order|
            index = order.batch_print_id
            pdf = ImageSticker.new(order, pdf).create(index)
            pdf.start_new_page
          end

          pdf
        end

        def orders_to_pdf(orders)
          pdf = Prawn::Document.new
          pdf = create_orders(pdf, orders)
          pdf.render
        end

        def stickers_to_pdf(orders)
          pdf = Prawn::Document.new
          pdf = create_stickers(pdf, orders)
          pdf.render
        end


        private
        def number_of_invoices(order)
          ( order_shipped_to_europe(order) ? 1 : 2)
        end

        def order_shipped_to_europe(order)
          (order.shipping_address.in_zone?('UK') || order.shipping_address.in_zone?('EU'))
        end
      end
    end
  end
end
