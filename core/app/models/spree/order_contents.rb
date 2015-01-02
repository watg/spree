module Spree
  class OrderContents
    attr_accessor :order, :currency, :line_item_builder

    def initialize(order)
      @order = order
      @currency ||= order.currency || Spree::Config[:currency]
    end

    #  Sale feature
    ## Transfer from spree extension product-assembly with options
    #
    def add(variant, quantity=1, options = {})

      uuid = Spree::VariantUuid.fetch(variant, options[:parts], options[:personalisations]).number
      line_item = grab_line_item(variant, uuid, options[:target_id], false)

      if !line_item
        line_item = build_line_item(variant, uuid, options)
      end

      add_by_line_item(line_item, quantity, options[:shipment])
    end

    def add_by_line_item(line_item, quantity, shipment=nil)

      line_item = eager_load(line_item)

      line_item.quantity += quantity
      line_item.target_shipment = shipment if shipment
      if line_item.save
        reload_totals
        shipment.present? ? shipment.update_amounts : order.ensure_updated_shipments
        PromotionHandler::Cart.new(order, line_item).activate
        ItemAdjustments.new(line_item).update
        reload_totals
      end
      line_item
    end


    # Remove variant qty from line_item
    # We need to fix the method below if we ever plan to use the api for incrementing and
    # decrementing line_items
    def remove(variant, quantity=1, options={})
      uuid = Spree::VariantUuid.fetch(variant, options[:parts], options[:personalisations]).number
      line_item = grab_line_item(variant, uuid, options[:target_id], true)

      remove_by_line_item(line_item, quantity, options[:shipment])
    end

    def delete_line_item(line_item, shipment=nil)
      remove_by_line_item(line_item, line_item.quantity, shipment)
    end

    def remove_by_line_item(line_item, quantity, shipment=nil)

      line_item = eager_load(line_item)

      if remove_from_line_item(line_item, quantity, shipment)
        reload_totals
        shipment.present? ? shipment.update_amounts : order.ensure_updated_shipments
        PromotionHandler::Cart.new(order, line_item).activate
        ItemAdjustments.new(line_item).update
        reload_totals
      end
      line_item
    end

    def update_cart(params)
      if order.update_attributes(params)
        order.line_items = order.line_items.select {|li| li.quantity > 0 }
        # Update totals, then check if the order is eligible for any cart promotions.
        # If we do not update first, then the item total will be wrong and ItemTotal
        # promotion rules would not be triggered.
        reload_totals
        PromotionHandler::Cart.new(order).activate
        order.ensure_updated_shipments
        reload_totals
        true
      else
        false
      end
    end

    private

    def remove_from_line_item(line_item, quantity, shipment)

      line_item.quantity -= quantity
      line_item.target_shipment = shipment

      if line_item.quantity <= 0
        line_item.destroy
      else
        line_item.save
      end

    end

    def build_line_item(variant, uuid, options)

      line_item = order.line_items.new(
        quantity: 0,
        variant: variant,
        currency: currency,
        target_id: options[:target_id],
        product_page_id: options[:product_page_id],
        product_page_tab_id: options[:product_page_tab_id],
        suite_id: options[:suite_id],
        suite_tab_id: options[:suite_tab_id],
        price:  variant.current_price_in(currency).amount,
        normal_price:  variant.price_normal_in(currency).amount,
        in_sale: variant.in_sale,
        item_uuid: uuid
      )
      line_item.line_item_parts = options[:parts] || []
      line_item.line_item_personalisations = options[:personalisations] || []

      amount_all_options = line_item.options_and_personalisations_price
      if amount_all_options > 0
        line_item.price += amount_all_options
        line_item.normal_price += amount_all_options
      end
      line_item
    end

    def grab_line_item(variant, uuid, target_id, raise_error=false)

      line_item = order.line_items.detect do |li|
        li.variant_id == variant.id &&
          li.item_uuid == uuid &&
          li.target_id.to_i == target_id.to_i
      end

      if !line_item.present? && raise_error
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      line_item
    end

    def order_updater
      @updater ||= OrderUpdater.new(order)
    end

    def reload_totals
      order_updater.update_item_count
      order_updater.update
      order.reload
    end

    # It is important that we eager load the line_item with it's
    # siblings to ensure the validations on save work
    def eager_load(line_item)
      line_item = order.line_items.detect { |li| li == line_item }
    end

  end

end
