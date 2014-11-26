module Spree
  class FeederRequirement

    def list
      inventory_units_inject({}) do |feeds, variant, location|
        feeds[location] ||= Hash.new(0)
        feeds[location][variant] += 1
        feeds
      end
    end

    def plan
      list.inject({}) do |movements, requirement|
        loc, variants = requirement
        variants.each_pair do |variant, count|
          remaining = count
          loc.feeders.each do |feeder|
            pick = [feeder.count_on_hand(variant), remaining].min
            if pick > 0
              remaining -= pick
              movements[loc] ||= {}
              movements[loc][feeder] ||= {}
              movements[loc][feeder][variant] = pick
            end
            break if remaining <= 0
          end
        end
        movements
      end
    end

    private

    def inventory_units_inject(acc, &block)
      units = Spree::InventoryUnit.last_24_hours.awaiting_feed.
        includes(shipment: [:stock_location]).
        includes(:variant)
      units.each do |iu|
        variant = iu.variant
        location = iu.shipment.stock_location
        acc = yield(acc, variant, location)
      end
      acc
    end
  end
end
