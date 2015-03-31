module Spree
  module StockTransferService
    class Create < ActiveInteraction::Base

      array :variants do
        integer
      end
      array :suppliers do
        integer
      end
      array :quantities do
        integer
      end
      string :reference
      integer :transfer_receive_stock, default: nil
      integer :transfer_source_location_id
      integer :transfer_destination_location_id

      def execute
        stock_transfer_items = []

        variants.each_with_index do |variant_id, i|
          variant = Spree::Variant.find(variant_id)
          supplier = Spree::Supplier.find(suppliers[i])
          quantity = quantities[i].to_i

          stock_transfer_items << Spree::StockTransfer::TransferItem.new(variant, quantity, supplier)
        end

        stock_transfer = StockTransfer.create(:reference => reference)
        if stock_transfer.valid?
          stock_transfer.transfer(source_location,
                                  destination_location,
                                  stock_transfer_items)

          stock_transfer
        else
          errors.merge!(stock_transfer.errors)
        end
      end

      private

      def source_location
        transfer_receive_stock ? nil : StockLocation.find(transfer_source_location_id)
      end

      def destination_location
        StockLocation.find(transfer_destination_location_id)
      end

    end
  end
end
