module Spree
  module PDF
    class CommercialInvoice
      extend Common

      WATG_LOGO = File.expand_path(File.join(File.dirname(__FILE__), 'images', 'logo-watg-135x99.png')) unless defined?(WATG_LOGO)

      class << self
        def create(pdf, order, batch_index=nil)
          initialmove_y = 5
          address_x = 35
          invoice_header_x = 325
          lineheight_y = 12

          set_font(pdf)
          pdf.text_box batch_index.to_s, at: [10, 40], height: 30, width: 100 if batch_index

          pdf.move_down initialmove_y

          watg_details(pdf, address_x, lineheight_y)
          watg_logo(pdf)
          customer_address(pdf, order, address_x, lineheight_y)
          invoice_details(pdf, order, invoice_header_x)
          invoice_terms(pdf)
          invoice_signature(pdf)

          pdf
        end

        private
        def set_font(pdf)
          # Add the font style and size
          pdf.font "Helvetica"
          pdf.font_size 9
          pdf
        end

        def watg_details(pdf, address_x, lineheight_y)
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

          pdf
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

          pdf
        end

        def invoice_details(pdf, order, invoice_header_x)

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

          invoice_services_data = [ [ 'item', 'sku', 'type', 'contents', 'options', 'price', 'qty', 'total' ] ]
          order.line_items.each do |item|
            invoice_services_data << [
              item.variant.product.name,
              item.variant.sku,
              item.product.product_type,
              '-',
              item.variant.option_values.empty? ? '' : item.variant.options_text,
              item.single_money.to_s,
              item.quantity,
              item.display_amount.to_s
            ]
            if item.product.product_type == 'kit' or item.product.product_type == 'virtual_product'
              item.line_item_options.each do |p|
                invoice_services_data << [
                  '-',
                  '-',
                  'part',
                  p.variant.name,
                  p.variant.option_values.empty? ? '' : p.variant.options_text,
                  '-',
                  p.quantity,
                  '-',
                ]
              end
            end
            item.line_item_personalisations.each do |p|
              invoice_services_data << [
                '-',
                '-',
                'personalisation',
                p.name,
                p.data_to_text,
                '-',
                '-',
                '-',
              ]
            end
          end

          pdf.table(invoice_services_data, :width => pdf.bounds.width) do
            style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
            style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
            style(row(0).columns(0..-1), :borders => [:top, :bottom])
            style(row(0).columns(0), :borders => [:top, :left, :bottom])
            style(row(0).columns(-1), :borders => [:top, :right, :bottom])
            style(row(-1), :border_width => 2)
            style(column(2..-1), :align => :right)
            style(columns(0), :width => 70)
            style(columns(1), :width => 60)
            style(columns(2), :width => 70)
            style(columns(3), :width => 70)
            style(columns(4), :width => 150)
            style(columns(5), :width => 40)
            style(columns(6), :width => 30)
          end

          pdf.move_down 1

          invoice_services_totals_data = [ [ "Sub Total", order.display_item_total.to_s ] ]
          order.adjustments.eligible.each do |adjustment|
            next if (adjustment.originator_type == 'Spree::TaxRate') and (adjustment.amount == 0)
            invoice_services_totals_data  << [ adjustment.label ,  adjustment.display_amount.to_s ]
          end
          invoice_services_totals_data.push [ "Order Total", order.display_total.to_s ]

          pdf.table(invoice_services_totals_data, :position => invoice_header_x, :width => 215) do
            style(row(0..1).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
            style(row(0), :font_style => :bold)
            style(row(2), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
            style(column(1), :align => :right)
            style(row(2).columns(0), :borders => [:top, :left, :bottom])
            style(row(2).columns(1), :borders => [:top, :right, :bottom])
          end

          pdf
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

          pdf
        end



        def invoice_signature(pdf)
          pdf.move_down 25

          signature_data = [ 
            ["Name", "Signature", "Date"],
            ['','' ,'' ],
          ]

          pdf.table(signature_data, :width => 350) do
            style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
            style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
            style(row(0).columns(0..-1), :borders => [:top, :bottom])
            style(row(0).columns(0), :borders => [:top, :left, :bottom])
            style(row(0).columns(-1), :borders => [:top, :right, :bottom])
            style(row(1), :border_width => 2, :height => 20 )
          end

          pdf
        end


      end
    end
  end
end
