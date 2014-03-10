module Spree
  module PDF
    class CommercialInvoice
      include Common

      WATG_LOGO = File.expand_path(File.join(File.dirname(__FILE__), 'images', 'logo-watg-135x99.png')) unless defined?(WATG_LOGO)
      attr_reader :order, :pdf, :currency

      def initialize(order, pdf = nil)
        @order = order
        @pdf = pdf || Prawn::Document.new
        @currency = order.currency

        # hash of unique products 
        # :id => {:product, :quantity, :group, :total_price, :single_price}
        @unique_products = {} 
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
        #start with EON Media Group
        pdf.text_box "WOOL AND THE GANG Ltd", :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box "Unit C106", :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box "89a Shacklewell Lane", :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box "E8 2EB", :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box "London UK", :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.move_down lineheight_y
        pdf.text_box "Email: info@woolandthegang.com", :at => [address_x,  pdf.cursor]
      end

      def watg_logo
        last_measured_y = pdf.cursor
        pdf.move_cursor_to pdf.bounds.height
        pdf.move_down 20
        pdf.image WATG_LOGO, :width => 100, :position => :right
        pdf.move_cursor_to last_measured_y
      end

      def customer_address(address_x, lineheight_y)
        pdf.move_down 65
        last_measured_y = pdf.cursor

        pdf.text_box "#{order.shipping_address.firstname} #{order.shipping_address.lastname} ", :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box order.shipping_address.address1, :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box order.shipping_address.address2 || '', :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box order.shipping_address.city, :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box order.shipping_address.country.name, :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box order.shipping_address.zipcode, :at => [address_x,  pdf.cursor]
        pdf.move_down lineheight_y
        pdf.text_box order.shipping_address.phone, :at => [address_x,  pdf.cursor]

        pdf.move_cursor_to last_measured_y
      end

      def top_summary(invoice_header_x)
        invoice_header_data = [ 
          ["Invoice #", order.number ],
          ["Invoice Date", Time.now.strftime("%Y/%m/%d") ],
          ["Order Complete  Date", order.completed_at.strftime("%Y/%m/%d") ],
          ["Amount Due",   order.display_total.to_s ]
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
        invoice_data = [ [ 'Item', 'Harmonisation Code', 'MID', 'Weight (gr)', 'Price', 'Qty', 'Total' ] ]

        gather_order_products
        compute_prices

        @unique_products.each do |id, line|
          product = line[:product]
          group = line[:group]
          invoice_data << [
            product_description_cell(product.name, group),
            group.code,
            group.mid,
            product.weight,
            money(line[:single_price]),
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
          style(column(3..6), :align => :right)
          style(columns(0), :width => 110)
          style(columns(1), :width => 110)
          style(columns(2), :width => 100)
          style(columns(3), :width => 60)
          style(columns(4), :width => 60)
          style(columns(5), :width => 50)
          style(columns(6), :width => 50)
        end
      end

      def totals(invoice_header_x)
        pdf.move_down 1

        totals_data = [ [ "Sub Total", order.display_item_total.to_s ] ]
        order.adjustments.eligible.each do |adjustment|
          next if (adjustment.originator_type == 'Spree::TaxRate') and (adjustment.amount == 0)
          totals_data  << [ adjustment.label ,  adjustment.display_amount.to_s ]
        end
        totals_data.push [ "Order Total", order.display_total.to_s ]

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
      end


      def money(amount)
        Spree::Money.new(amount, { currency: currency }).to_s
      end


      # def round_to_two_places(amount)
      #   BigDecimal.new(amount.to_s).round(2, BigDecimal::ROUND_HALF_UP)
      # end

      def gather_order_products
        order.line_items.each do |item|
          if item.product.product_type != 'kit'
            add_to_products(item.product, item.quantity, item.base_price*item.quantity)
          else
            item.variant.required_parts_for_display.each do |variant|
              # refactor with the new product types
              group = variant.product.product_group
              next if group.name == 'knitters needles'
              next if group.name =~ /sticker/

              add_to_products(variant.product, variant.count_part, variant.price_normal_in(currency).amount * variant.count_part)
            end

            item.line_item_options.each do |part|
              add_to_products(part.variant.product, part.quantity, part.price * part.quantity)
            end
          end
        end
      end

      def compute_prices
        total_amount = 0
        accummulated_amount = 0

        # weighted sum of the total amount
        @unique_products.each do |id, item|
          d {item[:total_amount]}
          total_amount += item[:total_amount]
        end

        number_of_items = @unique_products.count - 1 # -1 to match the index counter
        # @unique_products = Hash[@unique_products.to_a.reverse]
        @unique_products.each_with_index do |(id, item), index|
          if number_of_items == index # this is the last part
            item[:total_price] = order.item_total - accummulated_amount
            item[:single_price] = item[:total_price] / item[:quantity]
          else
            # weighted calculation
            proportion = item[:total_amount] / total_amount
            d { proportion }
            item[:total_price] = (proportion * order.item_total).round.to_f
            d {item[:total_price]}
            item[:single_price] = item[:total_price] / item[:quantity]
            accummulated_amount += item[:total_price]
          end
        end
      end

      def add_to_products(product, quantity, amount)
        if @unique_products.has_key?(product.id)
          @unique_products[product.id][:quantity] += quantity
          @unique_products[product.id][:total_amount] += amount
        else
          @unique_products[product.id] = {
            product: product,
            group: product.product_group,
            quantity: quantity,
            total_amount: amount
          }
        end
      end


      def product_description_cell(product_name, group)
        "<b>" + product_name + "</b>" +
        "\n" + group.garment +
        "\n" + [group.fabric, group.origin].join(" - ") + 
        "\n" + group.contents
      end

    end
  end
end
