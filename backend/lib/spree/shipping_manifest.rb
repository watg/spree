module Spree
  class ShippingManifest
    attr_accessor :order, :currency

    def initialize(order)
      @order = order
      @currency = order.currency
      @order_total = @order.total

      if @order.adjustments.gift_card.any?
        amount_gift_cards = @order.adjustments.gift_card.to_a.sum(&:amount).abs
        @order_total += amount_gift_cards
      end

      # hash of unique products
      # :id => {:product, :quantity, :group, :total_price, :single_price}
      @unique_products = {}
    end

    def create
      gather_order_products
      compute_prices
      @unique_products
    end

    def order_total
      @order_total
    end

    def shipping_cost
      cost = order.ship_total - order.shipping_discount
      Spree::Money.new(cost, { currency: currency })
    end

  private

    def gather_order_products
      order.line_items.includes(:variant => :product).each do |line|
        if line.parts.empty?
          add_to_products(line.product, line.quantity, line.base_price*line.quantity)
        else
          amount_required_parts = 0
          line.parts.required.each do |part|
            amount_required_parts += part.price * part.quantity * line.quantity
          end

          line.parts.each do |part|
            variant = part.variant
            # refactor with the new product types / categorizations
            group = variant.product.product_group
            next if group.name == 'knitters needles'
            next if group.name =~ /sticker/

            if part.optional
              amount = part.price * part.quantity * line.quantity
            else
              # to get a more accurate price figure than the standard normal price for the item
              # let's use the weighted amount of the base price, which includes only required parts
              amount = (part.price * part.quantity / amount_required_parts ) * line.base_price if amount_required_parts > 0
            end
            add_to_products(variant.product, part.quantity * line.quantity, amount || 0)
          end
        end
      end
    end

    def compute_prices
      total_amount = 0
      accummulated_amount = 0
      order_total_without_shipping = @order_total - shipping_cost.to_f

      # weighted sum of the total amount
      @unique_products.each do |id, item|
        total_amount += item[:total_amount]
      end

      number_of_items = @unique_products.count - 1 # -1 to match the index counter
      @unique_products.each_with_index do |(_id, item), index|
        if number_of_items == index # this is the last part
          item[:total_price] = order_total_without_shipping - accummulated_amount
          item[:single_price] = round_to_two_places(item[:total_price] / item[:quantity])
        else
          # weighted calculation
          proportion = item[:total_amount] / total_amount
          if proportion == 1.0
            item[:total_price] = order_total_without_shipping
          else
            item[:total_price] = (proportion * order_total_without_shipping).round.to_f
          end
          item[:single_price] = round_to_two_places(item[:total_price] / item[:quantity])
          accummulated_amount += item[:total_price]
        end
      end
    end

    def add_to_products(product, quantity, amount)
      if @unique_products.has_key?(product.id)
        @unique_products[product.id][:quantity] += quantity
        @unique_products[product.id][:total_amount] += amount
      else
        @unique_products[product.id] = {
          product: product,
          group: product.product_group,
          quantity: quantity,
          total_amount: amount
        }
      end
    end


    def round_to_two_places(amount)
      BigDecimal.new(amount.to_s).round(2, BigDecimal::ROUND_HALF_UP)
    end

  end
end