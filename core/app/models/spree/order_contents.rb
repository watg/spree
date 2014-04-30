module Spree
  class OrderContents
    attr_accessor :order, :currency

    def initialize(order)
      @order = order
    end

    #  Sale feature
    ## Transfer from spree extension product-assembly with options
    #
    def add(variant, quantity=1, currency=nil, shipment=nil, parts=nil, personalisations=nil, target_id=nil)
      parts ||= []
      personalisations ||= []
      currency ||= Spree::Config[:currency] # default to that if none is provided
      line_item = add_to_line_item(variant, quantity, currency, shipment, parts, personalisations, target_id)
      reload_totals
      PromotionHandler::Cart.new(order, line_item).activate
      ItemAdjustments.new(line_item).update
      reload_totals
      line_item
    end

    # Remove variant qty from line_item
    # We need to fix the method below if we ever plan to use the api for incrementing and 
    # decrementing line_items
    def remove(variant, quantity=1, shipment=nil, parts=nil, personalisations=nil, target_id=nil)
      line_item = grab_line_item_by_variant(variant, parts, personalisations, target_id, true)
      unsafe_remove_by_line_item(line_item, quantity, shipment)
      reload_totals
      PromotionHandler::Cart.new(order, line_item).activate
      ItemAdjustments.new(line_item).update
      reload_totals
      line_item
    end

    def add_by_line_item(line_item, quantity, shipment=nil)
      unsafe_add_by_line_item(line_item, quantity, shipment=nil)
      reload_totals
      PromotionHandler::Cart.new(order, line_item).activate
      ItemAdjustments.new(line_item).update
      reload_totals
      line_item
    end

    def delete_line_item(line_item)
      remove_by_line_item(line_item, line_item.quantity)
    end

    def remove_by_line_item(line_item, quantity, shipment=nil)
      unsafe_remove_by_line_item(line_item, quantity, shipment=nil)
      reload_totals
      PromotionHandler::Cart.new(order, line_item).activate
      ItemAdjustments.new(line_item).update
      reload_totals
      line_item
    end

    # Probably doesn't work
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

    def unsafe_add_by_line_item(line_item, quantity, shipment=nil)
      add_to_existing_line_item(line_item, quantity, shipment)
      line_item.save!
    end

    def unsafe_remove_by_line_item(line_item, quantity, shipment=nil)
      line_item.target_shipment = shipment

      line_item.quantity += -quantity.to_i

      if line_item.quantity <= 0
        line_item.destroy
      else
        line_item.save!
      end
    end

    def order_updater
      @updater ||= OrderUpdater.new(order)
    end

    def add_to_existing_line_item(line_item, quantity, shipment)
      line_item.target_shipment = shipment
      line_item.quantity += quantity.to_i
      line_item.currency = currency unless currency.nil?
    end

    def reload_totals
      order_updater.update_item_count
      order_updater.update_item_total
      order_updater.update_adjustment_total
      order_updater.persist_totals
      order.reload
    end

    def check_stock_levels_for_line_item(line_item)
      result = Spree::Stock::Quantifier.can_supply_order?(@order, line_item)
      result[:errors].each {|error_msg| @order.errors.add(:base, error_msg) }
      result[:in_stock]
    end

    def add_to_line_item(variant, quantity, currency, shipment, parts, personalisations, target_id)

      line_item = grab_line_item_by_variant(variant, parts, personalisations, target_id)

      if line_item
        add_to_existing_line_item(line_item, quantity, shipment)
      else
        line_item = order.line_items.new(quantity: quantity, variant: variant)
        line_item.target_shipment = shipment
        line_item.currency = currency unless currency.nil?
        line_item.add_parts(parts) 
        line_item.add_personalisations(personalisations)
        line_item.product_nature = variant.product.nature
        line_item.target_id = target_id

        line_item.price = variant.current_price_in(currency).amount
        line_item.normal_price = variant.price_normal_in(currency).amount

        amount_all_options = line_item.options_and_personalisations_price
        if amount_all_options > 0
          line_item.price += amount_all_options
          line_item.normal_price += amount_all_options
        end

        line_item.in_sale = variant.in_sale if variant.in_sale?

        line_item.item_uuid = Spree::VariantUuid.fetch(variant, parts, personalisations).number
      end

      line_item.save
      line_item
    end

    def grab_line_item_by_variant(variant, parts, personalisations, target_id, raise_error = false)
      line_item = order.find_existing_line_item(variant, parts, personalisations, target_id)

      if !line_item.present? && raise_error
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      line_item
    end

  end

end
