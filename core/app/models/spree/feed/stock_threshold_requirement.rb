module Spree
  module Feed
    class StockThresholdRequirement
      def list
        requirements = Hash.new { |hash, key| hash[key] = Hash.new(0) }

        locations = Spree::StockLocation.active
        locations.each do |location|
          StockThreshold.nonzero_for_location(location).includes(:variant).each do |st|
            shortfall = st.value - location.count_on_hand(st.variant)
            if shortfall > 0
              requirements[location][st.variant] += shortfall
            end
          end
        end

        requirements
      end
    end
  end
end
