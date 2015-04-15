module Admin
  class OrderPresenter < Spree::BasePresenter
    presents :order

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
