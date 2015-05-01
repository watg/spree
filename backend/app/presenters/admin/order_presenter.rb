module Admin
  class OrderPresenter < Spree::BasePresenter
    presents :order

    delegate :id, :shipments, :state, :parcels_grouped_by_box, :invoice_print_job, :image_sticker_print_job, :batch_sticker_print_date, :batch_invoice_print_date, :important?, :batch_print_id, :updated_at, :created_at, :completed_at, :number, :considered_risky, :payment_state, :shipment_state, :user, :email, :display_total, :express?, to: :order

    def self.model_name
      Spree::Order.model_name
    end
    
    def order_adjustments
      eligible_adjustments.order.to_a
    end

    def delivery_type_class
      if express?
        "express-delivery"
      else
        "normal-delivery"
      end
    end

    def delivery_type
      if express?
        "express"
      else
        "normal"
      end
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
