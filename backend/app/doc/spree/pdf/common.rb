module Spree
  module PDF
    module Common

      def to_pdf
        create
        pdf.render
      end

      def errors
        @errors ||= []
      end

      def to_pdf_file(filename)
        create
        pdf.render_file(filename)
      end
    end
  end
end
