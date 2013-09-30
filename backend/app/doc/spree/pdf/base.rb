module Spree
  module PDF
    class Base
      def self.to_pdf(filename, order)
        pdf = Prawn::Document.new
        pdf = create(pdf, order)
        pdf.render
      end

      def self.to_pdf_file(filename, order)
        pdf = Prawn::Document.new
        pdf = create(pdf, order)
        pdf.render_file(filename)
      end
    end
  end
end
