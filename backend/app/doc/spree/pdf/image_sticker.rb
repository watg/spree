module Spree
  module PDF
    class ImageSticker < Base
      ASSETS = {
        made_by_gang: File.join(Rails.root, 'app/assets/images/doc/', 'gang.jpg' ),
        made_by_you:  File.join(Rails.root, 'app/assets/images/doc/', 'you.jpg' )
      }

      FONTS = {
        bold:  File.join(Rails.root, 'app/assets/fonts', 'gillsansmtprobold.ttf'),
        light: File.join(Rails.root, 'app/assets/fonts', 'gillsansmtprolight.ttf'),
      }
      STICKER_COORDINATES_BOTTOM_LEFT = {x: 10, y: 40}
      LINE_HEIGHT = 10
      
      class << self
        def create(pdf, order, batch_index=nil)
          initial_y = pdf.cursor

          pdf.move_down  100
          pdf.font('Helvetica')
          pdf.text_box   batch_index.to_s, at: [10, initial_y], height: 30, width: 100 if batch_index
          pdf.font_size  50
          pdf.font(FONTS[:light])
          pdf.text_box   "HELLO", at: [10, (initial_y-100)], height: 55, width: 400
          pdf.font(FONTS[:bold])
          pdf.font_size  30
          pdf.text_box   firstname(order), at: [10, (initial_y - 140)], height: 30, width: 400

          pdf.move_down  100
          pdf.image      made_unique_by(order), width: 550
          pdf
        end

        private
        def made_unique_by(order)
          order.has_ready_made? ? ASSETS[:made_by_gang] : ASSETS[:made_by_you]
        end

        def firstname(order)
          order.shipping_address.firstname.upcase
        end

      end
    end
  end
end
