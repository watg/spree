module Spree
  module PDF
    class OrdersPrinter

      def initialize(orders)
        @orders = orders.order(:batch_print_id)
      end

      def print_invoices_and_packing_lists
        pdf = Prawn::Document.new

        count = @orders.count - 1
        @orders.each_with_index do |order, num|
          index = order.batch_print_id
          pdf = PackingList.new(order, pdf).create(index)
          
          if !shipped_to_europe?(order)
            pdf.start_new_page
            pdf = CommercialInvoice.new(order, pdf).create
          end
           
          if shipped_to_us_or_canada?(order)
            pdf.start_new_page
            pdf = CommercialInvoice.new(order, pdf).create
          end

          pdf.start_new_page unless count == num
        end

        pdf.render
      end

      def print_stickers
        pdf = Prawn::Document.new
        
        count = @orders.count - 1
        @orders.each_with_index do |order, num|
          index = order.batch_print_id
          pdf = ImageSticker.new(order, pdf).create(index)
          pdf.start_new_page unless count == num
        end

        pdf.render
      end


    private

      def shipped_to_us_or_canada?(order)
        north_america_zone = Spree::Zone.find_by(name: 'North America')
        north_america_zone.include?(order.shipping_address) if north_america_zone
      end

      def shipped_to_europe?(order)
        eu_zone = Spree::Zone.find_by(name: 'EU')
        eu_zone.include?(order.shipping_address) if eu_zone
      end
    end
  end
end
