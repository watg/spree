module Spree
  module PDF
    class Base
      def self.to_pdf(filename, order)
        pdf = Prawn::Document.new
        pdf = create(pdf, order)
        pdf.render
      end
    end
  end
end
