module Spree
  module PDF
    class CommercialInvoice
      include Common

      WATG_LOGO = File.expand_path(File.join(File.dirname(__FILE__), 'images', 'logo-watg-135x99.png')) unless defined?(WATG_LOGO)
      attr_reader :order, :pdf, :currency, :errors

      def initialize(order, pdf = nil)
        @order = order
        @pdf = pdf || Prawn::Document.new
        @currency = order.currency
        @errors = []

        shipping_manifest = Spree::ShippingManifestService.run(order: order)
        if shipping_manifest.valid?

          shipping_cost = shipping_manifest.result[:shipping_costs]
          @shipping_cost = Spree::Money.new(shipping_cost, { currency: @currency })

          @unique_products = shipping_manifest.result[:unique_products]
          @terms_of_trade_code = shipping_manifest.result[:terms_of_trade_code]
          order_total = shipping_manifest.result[:order_total]
          @order_display_total = Spree::Money.new(order_total, { currency: @currency })
        else
          @errors += shipping_manifest.errors
          return
        end
      end

      def create
        initialmove_y = 5
        address_x = 0
        invoice_header_x = 325
        lineheight_y = 12

        set_font

        pdf.move_down initialmove_y

        watg_details(address_x, lineheight_y)
        watg_logo
        customer_address(address_x, lineheight_y)

        top_summary(invoice_header_x)
        invoice_details
        totals(invoice_header_x)
        not_for_resale
        footer

        pdf
      end

    private

      def set_font
        # Add the font style and size
        pdf.font "Helvetica"
        pdf.font_size 9
      end

      def watg_details(address_x, lineheight_y)
        pdf.text "Commercial Invoice", leading: 8, size: 10, style: :bold
        pdf.text "WOOL AND THE GANG Ltd", leading: 1
        pdf.text "Unit C106", leading: 1
        pdf.text "89a Shacklewell Lane", leading: 1
        pdf.text "E8 2EB", leading: 1
        pdf.text "London UK", leading: 12
        pdf.text "Email: info@woolandthegang.com", leading: 1
        pdf.text "Tel: +44 (0) 207 241 6420"
      end

      def watg_logo
        last_measured_y = pdf.cursor
        pdf.move_cursor_to pdf.bounds.height
        pdf.move_down 20
        pdf.image WATG_LOGO, :width => 100, :position => :right
        pdf.move_cursor_to last_measured_y
      end

      def customer_address(address_x, lineheight_y)
        pdf.move_down 50
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

      def top_summary(invoice_header_x)
        invoice_header_data = [ 
          ["Invoice #", order.number ],
          ["Invoice Date", Time.now.strftime("%Y/%m/%d") ],
          ["Order Complete  Date", order.completed_at.strftime("%Y/%m/%d") ],
          ["Amount Due", @order_display_total.to_s_with_USD ]
        ]

        pdf.table(invoice_header_data, :position => invoice_header_x, :width => 215) do
          style(row(0..2).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
          style(row(3), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
          style(column(2), :align => :right)
          style(row(3).columns(0), :borders => [:top, :left, :bottom])
          style(row(3).columns(1), :borders => [:top, :right, :bottom])
        end

        pdf.move_down 45
      end

      def invoice_details
        invoice_data = [ [ 'Item', 'Harmonisation Code', 'MID', 'Weight (gr)', 'Price (' + order.currency + ')', 'Qty', 'Total' ] ]

        @unique_products.map do |line|
          product = line[:product]
          group = line[:group]
          invoice_data << [
            product_description_cell(product, group, line[:country]),
            group.code,
            line[:mid_code],
            product.weight,
            money(line[:total_price] / line[:quantity]),
            line[:quantity],
            money(line[:total_price])
          ]
        end

        pdf.table(invoice_data, :width => pdf.bounds.width, :cell_style => { :inline_format => true }) do
          style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
          style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
          style(row(0).columns(0..-1), :borders => [:top, :bottom])
          style(row(0).columns(0), :borders => [:top, :left, :bottom])
          style(row(0).columns(-1), :borders => [:top, :right, :bottom])
          style(row(-1), :borders => [:bottom], :border_width => 2, :border_color => 'dddddd')
          style(column(4..6), :align => :right)
          style(columns(0), :width => 110)
          style(columns(1), :width => 110)
          style(columns(2), :width => 100)
          style(columns(3), :width => 60)
          style(columns(4), :width => 70)
          style(columns(5), :width => 40)
          style(columns(6), :width => 50)
        end
      end

      def totals(invoice_header_x)
        pdf.move_down 1
        totals_data = []
        totals_data.push [ "Sub Total", (@order_display_total.money - @shipping_cost.money).format ]
        totals_data.push [ "Shipping", @shipping_cost.to_s ]
        totals_data.push [ "Order Total", @order_display_total.to_s_with_USD ]

        pdf.table(totals_data, :position => invoice_header_x, :width => 215) do
          style(row(0..-2), :padding => [1, 5, 1, 5], :borders => [])
          style(row(0), :font_style => :bold)
          style(row(-1), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
          style(column(1), :align => :right)
          style(row(-1).columns(0), :borders => [:top, :left, :bottom])
          style(row(-1).columns(1), :borders => [:top, :right, :bottom])
        end
      end

      def not_for_resale
        pdf.move_down 20
        pdf.text "Personal use - Not for re-sale", :align => :center
      end

      def footer
        pdf.bounding_box [pdf.bounds.left, pdf.bounds.bottom], :width  => pdf.bounds.width, :height => 25 do
          pdf.text 'Goods shipped by Wool and the Gang Ltd.    Company No. 8332008.    VAT No. GB 158 8398 50', size: 7
        end
        pdf.bounding_box [pdf.bounds.right - 100, pdf.bounds.bottom+5], :width  => 100, :height => 25 do
          pdf.text @terms_of_trade_code, size: 18, :align => :right, :style => :bold
        end
      end


      def money(amount)
        Spree::Money.new(amount, { currency: currency }).to_s
      end

      def product_description_cell(product, group, country)
        "<b>" + product.name + "</b>" +
        "\n" + group.garment +
        "\n" + [group.fabric, country.try(:name)].join(" - ") + 
        "\n" + group.contents
      end

    end
  end
end
