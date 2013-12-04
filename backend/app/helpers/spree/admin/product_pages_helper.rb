module Spree
  module Admin
    module ProductPagesHelper
      def tab_type(tab)
        case tab.tab_type
        when 'ready_to_wear'
          "Ready to wear / accessories"
        else
          tab.tab_type.to_s.humanize
        end
      end
    end
  end
end
