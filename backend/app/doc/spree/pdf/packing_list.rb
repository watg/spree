module Spree
  module PDF
    class PackingList
      include Common

      WATG_LOGO = File.expand_path(File.join(File.dirname(__FILE__), 'images', 'logo-watg-135x99.png')) unless defined?(WATG_LOGO)
      attr_reader :order, :pdf, :currency, :packing_list

      def initialize(order, pdf = nil)
        @order = order
        @pdf = pdf || Prawn::Document.new
        @currency = order.currency
        @packing_list = Spree::PackingListService.run(order: order).result
      end

      def create(batch_index = nil)
        initialmove_y = 5
        address_x = 35
        invoice_header_x = 325
        lineheight_y = 12

        set_font(pdf)
        pdf.text_box batch_index.to_s, at: [10, 40], height: 30, width: 100 if batch_index

        pdf.move_down initialmove_y

        watg_details(pdf, address_x, lineheight_y)
        shipping_type(pdf, order)
        watg_logo(pdf)
        customer_address(pdf, order, address_x, lineheight_y)
        invoice_details(pdf, order, invoice_header_x)
        invoice_terms(pdf)

        pdf
      end

    private
      def set_font(pdf)
        # Add the font style and size
        pdf.font "Helvetica"
        pdf.font_size 9
        pdf
      end

      def shipping_type(pdf, order)
        pdf.text "Express!", size: 40 , style: :bold, :align => :center if order.express?
      end

      def watg_details(pdf, address_x, lineheight_y)
        pdf.text "Packing List", leading: 10, size: 10, style: :bold
        pdf.text "WOOL AND THE GANG Ltd", leading: 2
        pdf.text "Unit C106", leading: 2
        pdf.text "89a Shacklewell Lane", leading: 2
        pdf.text "E8 2EB", leading: 2
        pdf.text "London UK", leading: 12
        pdf.text "Email: info@woolandthegang.com", leading: 2
        pdf.text "Tel: +44 (0) 207 241 6420"
      end

      def watg_logo(pdf)
        last_measured_y = pdf.cursor
        pdf.move_cursor_to pdf.bounds.height
        pdf.image WATG_LOGO, :width => 100, :position => :right
        pdf.move_cursor_to last_measured_y

        pdf
      end

      def customer_address(pdf, order, address_x, lineheight_y)
        pdf.move_down 65
        last_measured_y = pdf.cursor

        pdf.text "#{order.shipping_address.firstname} #{order.shipping_address.lastname}", leading: 1
        pdf.text order.shipping_address.address1, leading: 1
        pdf.text (order.shipping_address.address2 || ''), leading: 1
        pdf.move_down 10
        if state = order.shipping_address.state_text
          state = ', ' + state
        end
        pdf.text order.shipping_address.city + state.to_s, leading: 1

        pdf.text order.shipping_address.zipcode, leading: 1
        pdf.text order.shipping_address.country.name, leading: 6
        pdf.text order.shipping_address.phone, leading: 1

        pdf.move_cursor_to last_measured_y
      end

      def invoice_details(pdf, order, invoice_header_x)

        invoice_header_data = [
          ["Order #", order.number ],
          ["Invoice Date", Time.now.strftime("%Y/%m/%d") ],
          ["Order Complete  Date", order.completed_at.strftime("%Y/%m/%d") ],
          ["Amount Due",   order.display_total.to_s ]
        ]


        pdf.table(invoice_header_data, :position => invoice_header_x, :width => 215) do
          style(row(0..2).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
          style(column(2), :align => :centre)
          style(row(3), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
          style(row(3).columns(0), :borders => [:top, :left, :bottom])
          style(row(3).columns(1), :borders => [:top, :right, :bottom])
        end

        pdf.move_down 45

        body = packing_list.body
        all_data = packing_list.all_data

        # Don't be tempted to stick this in the invoce_data.any? below, this has scoping issues
        notify_airbrake(all_data) unless body.any?

        pdf.table(packing_list.all_data, :width => pdf.bounds.width, :cell_style => { :inline_format => true }) do
          # If we have more date that 1 row, then we have more than just the header.
          # Otherwise this blows up and ruins it for all the other commercial invoices
          if body.any?
            style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
          end
          style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
          style(row(0).columns(0..-1), :borders => [:top, :bottom])
          style(row(0).columns(0), :borders => [:top, :left, :bottom])
          style(row(0).columns(-1), :borders => [:top, :right, :bottom])
          style(row(-1), :border_width => 2)
          style(column(4..5), :align => :right)
          style(columns(0), :width => 120)
          style(columns(1), :width => 100)
          style(columns(2), :width => 120)
          style(columns(3), :width => 120)
          style(columns(4), :width => 30)
          style(columns(5), :width => 50)
          columns(0..5).valign = :center
        end
      end

      def invoice_terms(pdf)
        pdf.move_down 25

        invoice_terms_data = [
          ["Delivery Terms"],
          ["Goods shipped by Wool and the Gang"]
        ]

        pdf.table(invoice_terms_data, :width => 275) do
          style(row(0..-1).columns(0..-1), :padding => [1, 0, 1, 0], :borders => [])
          style(row(0).columns(0), :font_style => :bold)
        end

        if order.shipments.count > 1
          pdf.move_down 40
          pdf.text "Warning! This order has more than 1 shipment.", size: 24
        end

        pdf
      end

      def notify_airbrake(data)
        Helpers::AirbrakeNotifier.notify("Spree::PDF::PackingList data missing for order: #{order.number} ", data: data)
      end

    end
  end
end
