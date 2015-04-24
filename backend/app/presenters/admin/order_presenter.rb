module Admin
  class OrderPresenter < Spree::BasePresenter
    presents :order

    delegate :id, :state, :completed_at, :number, :considered_risky, :payment_state, :shipment_state, :user, :email, :display_total, to: :order
    def to_param
      @object.to_param
    end

    def to_key
      @object.to_key
    end

    def self.model_name
      Spree::Order.model_name
    end
    
    def order_adjustments
      eligible_adjustments.order.to_a
    end

    def line_item_adjustments
      eligible_adjustments.line_item.to_a
    end

    def selected_shipping_rate_adjustments
      eligible_adjustments.shipping_rate.select { |a| a.adjustable.selected }
    end

    private

    def all_adjustments
      Adjustments::Selector.new(order.all_adjustments)
    end

    def eligible_adjustments
      @eligible_adjustments ||= all_adjustments.eligible
    end
    
  end
end