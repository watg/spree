module Spree
  module PDF
    class OrdersToBeDispatched
      class << self
        
        def to_pdf(filename, orders)
          pdf = Prawn::Document.new
          
          orders.each_with_index do |order, batch_index|
            index = batch_index + 1
            number_of_invoices(order).times {
              pdf = Spree::PDF::CommercialInvoice.create(pdf, order, index)
              pdf.start_new_page
            }
            pdf = Spree::PDF::ImageSticker.create(pdf, order, index)
            pdf.start_new_page
          end
          
          pdf.render_file(filename)
        end
        
        private
        def number_of_invoices(order)
          ( order_shipped_in_europe(order) ? 1 : 2)
        end

        def order_shipped_in_europe(order)
          (order.shipping_address.in_zone?('UK') || order.shipping_address.in_zone?('EU'))
        end
      end
    end
  end
end
