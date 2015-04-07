module Spree
  module Api
    module Dashboard
      module Office
        # Find valid orders completed at today.
        class FindTodayValidOrders
          def initialize(valid_orders = nil)
            valid_orders ||= Spree::Order.complete.not_cancelled
            @orders = valid_orders
          end

          def run
            @orders.where("completed_at > ?", Time.zone.now.at_beginning_of_day)
              .where.not(email: "request@woolandthegang.com")
              .where(internal: false)
              .joins(payments: :payment_method)
              .merge(Spree::PaymentMethod.where(name: ["Credit Card", "PayPal"])).uniq
          end
        end
      end
    end
  end
end
