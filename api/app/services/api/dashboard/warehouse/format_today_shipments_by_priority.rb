module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of the number of today shipments for the dashboard api
      # divided by order type
      class FormatTodayShipmentsByPriority
        def initialize
          @shipments = Spree::Shipment.shipped
        end

        def run
          express, normal = today_shipments.partition { |o| o.express? }
          { express: express.count, normal: normal.count }
        end

        def today_shipments
          @shipments
          .where("shipped_at > ?", Time.zone.now.at_beginning_of_day)
        end

      end
    end
  end
end