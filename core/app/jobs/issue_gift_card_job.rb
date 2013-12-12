module Spree
  class IssueGiftCardJob < Struct.new(:order)
    def perform
      order.gift_card_line_items.each do |item|
        Spree::IssueGiftCardService.run(line_item: item, order: order)
      end
    end
  end
end
