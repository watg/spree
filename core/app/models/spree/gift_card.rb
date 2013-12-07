module Spree
  class GiftCard < ActiveRecord::Base
    STATES = %w(not_redeemed redeemed on_hold cancelled refunded)
    acts_as_paranoid
    
    belongs_to :variant
    belongs_to :buyer_order, class_name: 'Spree::Order'
    belongs_to :beneficiary_order,  class_name: 'Spree::Order'

    before_validation :creation_setup
    before_create     :generate_code

    private
    def creation_setup
      self.expiry_date = 1.year.from_now        if self.expiry_date.blank?
      self.buyer_email = self.buyer_order.email if self.buyer_email.blank? 
      self.state = STATES.first if self.state.blank?
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
      encode([buyer_email, buyer_order.id].join, 4)
    end

    def currency_value_uuid
      encode([currency, value, ::UUID.generate].join, 6)
    end

    def expiry_date_time_now
      encode([expiry_date, Time.now].join, 4)
    end
    
    def encode(string, length)
      Digest::MD5.hexdigest(string).upcase[0,length]
    end

    def set_expiry_date
      if self.expiry_date.blank?
        self.expiry_date = 1.year.from_now
      end
    end
  end
end
