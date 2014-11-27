module Spree
  class StockThreshold < ActiveRecord::Base
    belongs_to :variant
    belongs_to :stock_location

    scope :nonzero, -> { where("value > 0") }
    scope :nonzero_for_location, -> (location) { nonzero.where(stock_location: location) }
  end
end
