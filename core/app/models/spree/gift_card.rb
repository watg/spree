module Spree
  class GiftCard < ActiveRecord::Base
    NOT_REDEEMED = 'not_redeemed'
    REDEEMED = 'redeemed'
    STATES = [NOT_REDEEMED, REDEEMED] + %w(paused cancelled refunded)
    acts_as_paranoid

    belongs_to :buyer_order_line_item, class_name: "Spree::LineItem"
    belongs_to :buyer_order, class_name: 'Spree::Order'
    belongs_to :beneficiary_order,  class_name: 'Spree::Order'

    before_validation :creation_setup
    before_create     :generate_code

    validates :state, inclusion: { in: STATES }

    scope :redeemed, -> { where(state: REDEEMED) }

    state_machine :state, initial: :not_redeemed do
      event :redeem do
        transition from: [:not_redeemed], to: :redeemed
      end
      event :pause do
        transition from: [:not_redeemed], to: :paused
      end
      event :activate do
        transition from: [:paused, :redeemed], to: :not_redeemed
      end
      event :refund do
        transition from: [:not_redeemed, :redeemed, :paused], to: :refunded
      end
      event :cancel do
        transition from: [:not_redeemed, :paused], to: :cancelled
      end
    end

    class << self
      def match_gift_card_format?(code)
        !!(code =~ /\w{4}\-\w{6}\-\w{4}/)
      end
    end

    def change_state_to?(desired_state)
      _state  = {
        'not_redeemed' => 'activate',
        'redeemed' => 'redeem',
        'paused'   => 'pause',
        'cancelled'=> 'cancel',
        'refunded' => 'refund'
      }[desired_state]
      return false if _state.blank?
      self.send("can_#{_state}?".to_sym)
      rescue
      false
    end

    def create_adjustment(label, target, order, mandatory=false, state="open")
      amount = compute_amount(order)
      return if amount == 0 && !mandatory
      Spree::Adjustment.create!(
                                amount:     amount,
                                order:      order,
                                adjustable: order,
                                source:     self,
                                label:      label
                                )

      set_beneficiary(order)
    end

    def update_adjustment(adjustment, order)
      set_beneficiary(order)
      adjustment.update_column(:amount, compute_amount(order))
    end

    def eligible?(order)
      (self.expiry_date > Time.now ) && in_valid_state_for_use?(order)
    end

    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      # TODO: use calculator instead
      ( item_and_promo_total(calculable) > self.value ? self.value : item_and_promo_total(calculable)) * -1
    end

    def item_and_promo_total(calculable)
      calculable.item_total + (calculable.promo_total * -1)
    end

    def reactivate
      self.beneficiary_email = nil
      self.beneficiary_order = nil
      self.state = NOT_REDEEMED
      self.save
    end

    private
    def set_beneficiary(order)
      self.beneficiary_order = order
      self.beneficiary_email = order.email
      self.save
    end

    def in_valid_state_for_use?(order)
      if self.state == 'redeemed'
        return order == self.beneficiary_order
      else
        !%w(paused cancelled refunded).include?(self.state)
      end
    end

    def creation_setup
      self.expiry_date = 1.year.from_now        if self.expiry_date.blank?
      self.buyer_email = self.buyer_order.email if self.buyer_email.blank?
      self.state = NOT_REDEEMED                 if self.state.blank?
    end

    def generate_code
      if self.code.blank?
        self.code = [
                     buyer_email_buyer_order_id,
                     currency_value_uuid,
                     expiry_date_time_now
                    ].join('-')
      end
    end

    def buyer_email_buyer_order_id
      encode([buyer_email, buyer_order.try(:id) || SecureRandom.urlsafe_base64(5, false)].join, 4)
    end

    def currency_value_uuid
      encode([currency, value, ::UUID.generate].join, 6)
    end

    def expiry_date_time_now
      encode([expiry_date, Time.now].join, 4, -4)
    end

    def encode(string, length, offset=0)
      Digest::MD5.hexdigest(string).upcase[offset, length]
    end

    def set_expiry_date
      if self.expiry_date.blank?
        self.expiry_date = 1.year.from_now
      end
    end
  end
end
