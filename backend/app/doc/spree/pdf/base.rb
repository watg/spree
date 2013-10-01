module Spree
  module PDF
    class Base
      class << self
        def to_pdf(order)
          pdf = Prawn::Document.new
          pdf = create(pdf, order)
          pdf.render
        end

        def to_pdf_file(filename, order)
          pdf = Prawn::Document.new
          pdf = create(pdf, order)
          pdf.render_file(filename)
        end
      end
    end
  end
end
