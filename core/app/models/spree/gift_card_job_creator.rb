module Spree
  class GiftCardJobCreator
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def run
      jobs.each do |job|
        ::Delayed::Job.enqueue job, :queue => 'gift_card'
      end
    end

    private

    def jobs
      order.gift_card_line_items.flat_map do |item|
        item.quantity.times.map { |position|
          Spree::IssueGiftCardJob.new(order, item, position)
        }
      end
    end
  end
end
