# All tasks that need to be completed post a complete order live here
# NOTE: This is also used in the watg/better_spree_paypal_express plugin
module Spree
  class OrderPostCompleteService < ActiveInteraction::Base

    model :order, class: 'Spree::Order'
    string :tracking_cookie, default: nil
    # disabled, because we will use the new ga api on frontend
    def execute
    end


  end
end
