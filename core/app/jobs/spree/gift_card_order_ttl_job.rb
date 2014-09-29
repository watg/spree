module Spree
  GiftCardOrderTTLJob = Struct.new(:order, :gift_card) do
    def perform
      if not self.order.payments.completed.any?
        self.gift_card.reactivate

        adjustment = self.order.adjustments.gift_card.where(source_id: self.gift_card.id).first
        if adjustment
          adjustment.amount = 0
          adjustment.label = "[VOID] NOT USED WITHIN ALLOWED TIME -- #{adjustment.label}"
          adjustment.close! unless adjustment.closed?
          adjustment.save!
        end
      end
    end
  end
end
