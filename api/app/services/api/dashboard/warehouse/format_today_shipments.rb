module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of the number of today shipments for the dashboard api
      class FormatTodayShipments
        def initialize
          @shipments = Spree::Shipment.shipped
        end

        def run
          today_shipments = @shipments
                            .where("shipped_at > ?", Time.zone.now.at_beginning_of_day)
                            .count
          { total: today_shipments }
        end
      end
    end
  end
end