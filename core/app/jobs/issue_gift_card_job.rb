module Spree
  class IssueGiftCardJob < Struct.new(:order, :item, :position)
    def perform
      outcome = Spree::IssueGiftCardService.run(order: order, line_item: item, position: position)
      raise outcome.errors.message_list.join(" || ") unless outcome.success?
    end
  end
end
