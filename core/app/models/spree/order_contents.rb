module Spree
  class OrderContents
    attr_accessor :order, :currency

    def initialize(order)
      @order = order
    end

    #  Sale feature
    ## Transfer from spree extension product-assembly with options
    #
    def add(variant, quantity = 1, currency = nil, shipment = nil, parts, personalisations, target_id)
      currency ||= Spree::Config[:currency] # default to that if none is provided
      line_item = add_to_line_item(variant, quantity, currency, shipment, parts, personalisations, target_id)
      line_item
    end

    # Remove variant qty from line_item
    # We need to fix the method below if we ever plan to use the api for incrementing and 
    # decrementing line_items
    def remove(variant, quantity=1, shipment=nil)
      line_item = order.find_line_item_by_variant(variant)

      unless line_item
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      remove_from_line_item(line_item, variant, quantity, shipment)
    end
    
    private

    def check_stock_levels_for_line_item(line_item)
      result = Spree::Stock::Quantifier.can_supply_order?(@order, line_item)
      result[:errors].each {|error_msg| @order.errors.add(:base, error_msg) }
      result[:in_stock]
    end

    def add_to_line_item(variant, quantity, currency=nil, shipment=nil, parts, personalisations, target_id)

      line_item = grab_line_item_by_variant(variant, parts, personalisations, target_id)

      if line_item
        line_item.target_shipment = shipment
        line_item.quantity += quantity.to_i
        line_item.currency = currency unless currency.nil?
      else
        line_item = order.line_items.new(quantity: quantity, variant: variant)
        line_item.target_shipment = shipment
        line_item.currency = currency unless currency.nil?
        line_item.add_parts(parts) unless parts.blank?
        line_item.add_personalisations(personalisations) unless personalisations.blank?
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

      if check_stock_levels_for_line_item(line_item)
        line_item.save
      end

      line_item
    end

    def remove_from_line_item(line_item, variant, quantity, shipment=nil)
      line_item.quantity += -quantity
      line_item.target_shipment= shipment

      if line_item.quantity == 0
        Spree::OrderInventory.new(order).verify(line_item, shipment)
        line_item.destroy
      else
        line_item.save!
      end

      order.reload
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
