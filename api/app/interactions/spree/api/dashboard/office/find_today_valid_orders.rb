module Spree
  module Api
    module Dashboard
      module Office
        class FindTodayValidOrders
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            @orders.where('completed_at > ?', Time.zone.now.at_beginning_of_day).where.not(
              email: 'request@woolandthegang.com').where(internal: false).joins(payments: :payment_method).merge(
              Spree::PaymentMethod.where(name: ['Credit Card', 'PayPal'])).uniq
          end
        end
      end
    end
  end
end
