module Spree
  class StockTransfer < Spree::Base
    has_many :stock_movements, :as => :originator

    belongs_to :source_location, :class_name => 'StockLocation'
    belongs_to :destination_location, :class_name => 'StockLocation'

    make_permalink field: :number, prefix: 'T'

    validates :reference, uniqueness: true

    TransferItem = Struct.new(:variant, :quantity, :supplier)

    def to_param
      number
    end

    def source_movements
      stock_movements.joins(:stock_item)
        .where('spree_stock_items.stock_location_id' => source_location_id)
    end

    def destination_movements
      stock_movements.joins(:stock_item)
        .where('spree_stock_items.stock_location_id' => destination_location_id)
    end

    def transfer(source_location, destination_location, stock_transfer_items)
      transaction do
        stock_transfer_items.each do |item|
          source_location.unstock(item.variant, item.quantity, self, item.supplier) if source_location
          destination_location.restock(item.variant, item.quantity, self, item.supplier)

          self.source_location = source_location
          self.destination_location = destination_location
          self.save!
        end
      end
    end

    def receive(destination_location, stock_transfer_items)
      transfer(nil, destination_location, stock_transfer_items)
    end
  end
end
