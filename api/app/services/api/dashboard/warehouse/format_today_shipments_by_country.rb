module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of the number
      # shipments by country for the dashboard api
      class FormatTodayShipmentsByCountry
        def initialize
          @shipments = Spree::Shipment.shipped
                       .joins(address: [:country])
                       .select("spree_countries.name as name")
                       .where("shipped_at > ?", Time.zone.today.at_beginning_of_day)
        end

        def run
          short_countries_list(shipments_by_country)
        end

        def shipments_by_country
          shipments = @shipments.group_by(&:name).map do |key, line_items|
            {
              key => line_items.count
            }
          end
          shipments = Hash[*shipments.collect(&:to_a).flatten]
          shipments.sort_by { |hsh| - hsh.last } # orders the array by value in desc
        end

        def short_countries_list(shipments)
          if shipments.count > 10
            shipments[9] = ["others", (shipments[9..shipments.size].map(&:last).reduce(:+))]
            shipments = shipments[0..9]
          end
          shipments
        end
      end
    end
  end
end
