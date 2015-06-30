module Orders
  class PopulateService < ActiveInteraction::Base
    model :order, class: "Spree::Order"
    hash :params do
      integer :variant_id
      integer :quantity
      integer :suite_id
      integer :suite_tab_id
      integer :target_id, default: nil
      hash :options, strip: false, default: nil
    end

    set_callback :type_check, :before, -> { coerce_target_id }

    def execute
      populator = Spree::OrderPopulator.new(order, params)
      item = populator.populate
      order.ensure_updated_shipments unless item.errors.any?
      item
    end

    def coerce_target_id
      target = params[:target_id]
      params[:target_id] = target == "" ? nil : target
    end
  end
end
