module Spree
  module Admin
    module ProductPagesHelper
      def tab_type(tab)
        case tab.tab_type
        when 'made_by_the_gang'
          "Made by the gang / accessories"
        else
          tab.tab_type.to_s.humanize
        end
      end
    end
  end
end
