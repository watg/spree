module Spree
  module Admin
    module WaitingOrdersHelper
      def batch_number(i, page_number, per_page)
        i+1 + ((page_number-1) * per_page)
      end
    end
  end
end
