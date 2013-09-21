module Spree
  module PDF
    class OrdersToBeDispatched 
      class << self
        def create(pdf, orders)
          orders.each_with_index do |order, batch_index|
            index = batch_index + 1
            number_of_invoices(order).times {
              pdf = CommercialInvoice.create(pdf, order, index)
              pdf.start_new_page
            }
            pdf = ImageSticker.create(pdf, order, index)
            pdf.start_new_page
          end
          
          pdf
        end
        
        def to_pdf(filename, order)
          pdf = Prawn::Document.new
          pdf = create(pdf, order)
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
