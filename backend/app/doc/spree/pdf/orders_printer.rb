module Spree
  module PDF
    class OrdersPrinter

      def initialize(orders)
        @orders = orders
      end

      def print_invoices_and_packing_lists
        pdf = Prawn::Document.new

        count = @orders.count - 1
        @orders.each_with_index do |order, num|
          index = order.batch_print_id
          pdf = PackingList.new(order, pdf).create(index)
          
          if !shipped_to_europe?(order)
            pdf.start_new_page
            # switch the two lines below when deploying the new Commercial Invoice
            # pdf = CommercialInvoice.new(order, pdf).create
            pdf = PackingList.new(order, pdf).create(index) 
          end

          pdf.start_new_page unless count == num
        end

        pdf.render
      end

      def print_stickers
        pdf = Prawn::Document.new
        
        @orders.each do |order|
          index = order.batch_print_id
          pdf = ImageSticker.new(order, pdf).create(index)
          pdf.start_new_page
        end

        pdf.render
      end


    private

      # def number_of_invoices(order)
      #   ( shipped_to_europe?(order) ? 1 : 2)
      # end

      def shipped_to_europe?(order)
        zone = Spree::Zone.match(order.shipping_address)
        return true if zone.name == 'UK' or zone.name  == 'EU'
      end
    end
  end
end
