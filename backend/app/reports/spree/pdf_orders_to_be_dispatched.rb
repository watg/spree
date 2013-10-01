module Spree
  module PDF
    class OrdersToBeDispatched
    ASSETS = {
      made_by_gang: File.join(Rails.root, 'app/assets/images/', 'POSTLabel-BYTHEGANG.jpg' ),
      made_by_you:  File.join(Rails.root, 'app/assets/images/', 'POSTLabel-BYYOU.jpg' )
    }

    STICKER_COORDINATES_BOTTOM_LEFT = {x: 10, y: 40}

    class << self
      
      def to_pdf(filename, orders)
        pdf = Prawn::Document.new
        
        orders.each_with_index do |order, batch_index|
          number_of_invoices(order).times {
            pdf = commercial_invoice.create(pdf, order, batch_index)
            pdf.start_new_page
          }
          pdf = image_stiker.create(pdf, order, batch_index)
        end

        pdf.render_file(filename)
      end

      private

      def number_of_invoices(order)
       (order.shipping_address_in_euro_zone? ? 1 : 2)
      end

      def commercial_invoice
        Spree::PDF::CommercialInvoice
      end
      def image_stiker
        Spree::PDF::ImageStiker
      end
      
    end
  end
end
end
