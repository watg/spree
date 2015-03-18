# All tasks that need to be completed post a complete order live here
# NOTE: This is also used in the watg/better_spree_paypal_express plugin
module Spree
  class OrderPostCompleteService < ActiveInteraction::Base

    model :order, class: 'Spree::Order'
    string :tracking_cookie, default: nil

    def execute
      run_analytic_job(order, tracking_cookie)
    end

    def run_analytic_job(order, tracking_cookie)
      analytic_job = Spree::AnalyticJob.new(
        event: :transaction,
        order: order,
        user_id: tracking_cookie
      )
      ::Delayed::Job.enqueue(analytic_job, queue: 'analytics')
    end


  end
end
