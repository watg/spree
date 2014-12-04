module Spree
  module ServiceTrait
    module StockThresholds

      def update_stock_thresholds(stock_thresholds, master)
        stock_thresholds.each do |location_id, threshold|
          stock_threshold = master.stock_thresholds.
            where(stock_location_id: location_id.to_s).first_or_initialize
          stock_threshold.value = threshold
          stock_threshold.save
        end
      end

    end
  end
end
