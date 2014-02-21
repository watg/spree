class Spree::PaypalAccount < ActiveRecord::Base
  has_many :payments, :as => :source

  def actions
    %w{capture credit}
  end

  def transaction_id
    nil
  end

  def token
    nil
  end

  def refund_transaction_id
    nil
  end

  def refunded_at
    nil
  end

  def refunded_type
    nil
  end

  def state
    nil
  end

  def can_capture?(payment)
    !echeck?(payment) && payment.state == "pending"
  end

  def can_credit?(payment)
    return false unless payment.state == "completed"
    return false unless payment.order.payment_state == "credit_owed"
    # payment.credit_allowed > 0
    # !payment.payment_method.find_capture(payment).nil?
    return nil
  end

  # fix for Payment#payment_profiles_supported?
  def payment_gateway
    false
  end

  def echeck?(payment)
    # logs = payment.log_entries.all(:order => 'created_at DESC')
    # logs.each do |log|
    #   details = YAML.load(log.details) # return the transaction details
    #   if details.params['payment_type'] == 'echeck'
    #     return true
    #   end
    # end
    # return false
    return nil
  end

end
