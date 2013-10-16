module Spree
  class CommercialInvoice < ::Prawn::Document
    def to_pdf(order)

      logopath = File.join(Rails.root, 'app/assets/images/', 'logo-watg-135x99.png' )
      initial_y = cursor
      initialmove_y = 5
      address_x = 35
      invoice_header_x = 325
      lineheight_y = 12
      font_size = 9

      move_down initialmove_y

      # Add the font style and size
      font "Helvetica"
      font_size font_size

      #start with EON Media Group
      text_box "WOOL AND THE GANG Ltd", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "Unit C106", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "89a Shacklewell Lane", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "E8 2EB", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box "London UK", :at => [address_x,  cursor]
      move_down lineheight_y
      move_down lineheight_y
      text_box "Email: info@woolandthegang.com", :at => [address_x,  cursor]

      last_measured_y = cursor
      move_cursor_to bounds.height

      image logopath, :width => 100, :position => :right

      move_cursor_to last_measured_y

      # client address
      move_down 65
      last_measured_y = cursor

      text_box "#{order.shipping_address.firstname} #{order.shipping_address.lastname} ", :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.address1, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.address2 || '', :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.city, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.country.name, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.zipcode, :at => [address_x,  cursor]
      move_down lineheight_y
      text_box order.shipping_address.phone, :at => [address_x,  cursor]

      move_cursor_to last_measured_y

      invoice_header_data = [ 
        ["Invoice #", order.number ],
        ["Invoice Date", Time.now.strftime("%Y/%m/%d") ],
        ["Amount Due",   order.display_total.to_s ]
      ]


      table(invoice_header_data, :position => invoice_header_x, :width => 215) do
        style(row(0..1).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
        style(row(2), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(column(1), :align => :right)
        style(row(2).columns(0), :borders => [:top, :left, :bottom])
        style(row(2).columns(1), :borders => [:top, :right, :bottom])
      end

      move_down 45

      invoice_services_data = [ [ 'item', 'sku', 'type', 'contents', 'options', 'price', 'quantity', 'total' ] ]
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

          item.variant.required_parts_for_display.each do |p|
            invoice_services_data << [
              '-',
              'part',
              p.name,
              p.option_values.empty? ? '' : p.options_text,
              '-',
              p.count_part,
              '-',
            ]
          end
          item.line_item_options.each do |p|
            invoice_services_data << [
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

      end

      table(invoice_services_data, :width => bounds.width) do
        style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
        style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(row(0).columns(0..-1), :borders => [:top, :bottom])
        style(row(0).columns(0), :borders => [:top, :left, :bottom])
        style(row(0).columns(-1), :borders => [:top, :right, :bottom])
        style(row(-1), :border_width => 2)
        style(column(2..-1), :align => :right)
        style(columns(0), :width => 50)
        style(columns(1), :width => 50)
        style(columns(2), :width => 50)
        style(columns(3), :width => 50)
        style(columns(4), :width => 150)
      end

      move_down 1

      invoice_services_totals_data = [ [ "Sub Total", order.display_item_total.to_s ] ]
      order.adjustments.eligible.each do |adjustment|
        next if (adjustment.originator_type == 'Spree::TaxRate') and (adjustment.amount == 0)
        invoice_services_totals_data  << [ adjustment.label ,  adjustment.display_amount.to_s ]
      end
      invoice_services_totals_data.push [ "Order Total", order.display_total.to_s ]

      table(invoice_services_totals_data, :position => invoice_header_x, :width => 215) do
        style(row(0..1).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
        style(row(0), :font_style => :bold)
        style(row(2), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(column(1), :align => :right)
        style(row(2).columns(0), :borders => [:top, :left, :bottom])
        style(row(2).columns(1), :borders => [:top, :right, :bottom])
      end

      move_down 25

      invoice_terms_data = [ 
        ["Delivery Terms"],
        ["Goods shipped by Wool and the Gang"]
      ]

      table(invoice_terms_data, :width => 275) do
        style(row(0..-1).columns(0..-1), :padding => [1, 0, 1, 0], :borders => [])
        style(row(0).columns(0), :font_style => :bold)
      end

      move_down 25

      signature_data = [ 
        ["Name", "Signature", "Date"],
        ['','' ,'' ],
      ]

      table(signature_data, :width => 350) do
        style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
        style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
        style(row(0).columns(0..-1), :borders => [:top, :bottom])
        style(row(0).columns(0), :borders => [:top, :left, :bottom])
        style(row(0).columns(-1), :borders => [:top, :right, :bottom])
        style(row(1), :border_width => 2, :height => 20 )
      end

      render
    end
  end


end

