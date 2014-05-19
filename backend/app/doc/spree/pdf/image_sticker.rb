module Spree
  module PDF
    class ImageSticker
      include Common

      ASSETS = {
        made_by_gang: File.expand_path(File.join(File.dirname(__FILE__), 'images', 'gang.jpg')),
        made_by_you: File.expand_path(File.join(File.dirname(__FILE__), 'images', 'you.jpg'))
      } unless defined?(ASSETS)

      FONTS = {
        medium: File.expand_path(File.join(File.dirname(__FILE__), 'fonts', 'gillsansmtpromedium.ttf')),
        light: File.expand_path(File.join(File.dirname(__FILE__), 'fonts', 'gillsansmtprolight.ttf'))
      } unless defined?(FONTS)
      
      STICKER_COORDINATES_BOTTOM_LEFT = {x: 10, y: 40}    unless defined?(STICKER_COORDINATES_BOTTOM_LEFT)
      LINE_HEIGHT = 10                                    unless defined?(LINE_HEIGHT)
      
      attr_reader :order, :pdf

      def initialize(order, pdf = nil)
        @order = order
        @pdf = pdf || Prawn::Document.new
      end

      def create(batch_index=nil)
        initial_y = pdf.cursor

        pdf.move_down  100
        pdf.font_size  12
        pdf.font('Helvetica')
        pdf.text_box   batch_index.to_s, at: [10, initial_y], height: 30, width: 100 if batch_index
        pdf.font_size  45
        pdf.font(FONTS[:light])
        pdf.text_box   "HELLO", at: [23, (initial_y-80)], height: 45, width: 400
        pdf.font_size  42
        pdf.font(FONTS[:medium])
        pdf.text_box   firstname, at: [23, (initial_y - 115)], height: 45, width: 400

        pdf.move_down  135
        pdf.image      made_unique_by, width: 550
        pdf
      end

      private
      def made_unique_by
        ready_to_wear = order.line_items.detect do |line|
          line.product.marketing_type.rtw?
        end
        ready_to_wear ? ASSETS[:made_by_gang] : ASSETS[:made_by_you]
      end

      def firstname
        order.shipping_address.firstname.upcase
      end

    end
  end
end
