module Spree
  module PDF
    class OrdersPrinter
      attr_accessor :errors

      def initialize(orders)
        @orders = orders.sort_by(&:batch_print_id)
        @errors = []
      end

      def print_invoices_and_packing_lists
        pdf = Prawn::Document.new

        count = @orders.count - 1
        @orders.each_with_index do |order, num|
          index = order.batch_print_id
          pdf = PackingList.new(order, pdf).create(index)

          if !shipped_to_europe?(order)
            pdf = create_commercial_invoice(order, pdf)
          end

          # here we simply add one more commercial invoice
          # as we need 2 of them when shipping to US or Canada
          if shipped_to_us_or_canada?(order)
            pdf = create_commercial_invoice(order, pdf)
          end

          pdf.start_new_page unless count == num
        end

        pdf.render unless errors.any?
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

      def create_commercial_invoice(order, pdf)
        pdf.start_new_page
        commercial_invoice = CommercialInvoice.new(order, pdf)
        if commercial_invoice.errors.any?
          @errors += commercial_invoice.errors
        else
          pdf = commercial_invoice.create
        end
        pdf
      end

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
