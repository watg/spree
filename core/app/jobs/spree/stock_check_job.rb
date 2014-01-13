module Spree
  class StockCheckJob < Struct.new(:stock_item)
    def perform
      #TODO: raise "define me"
    end
  end
end
