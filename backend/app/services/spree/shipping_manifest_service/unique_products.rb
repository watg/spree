module Spree

  class ShippingManifestService::UniqueProducts < ActiveInteraction::Base

    model :order, class: 'Spree::Order'
    model :order_total, class: 'BigDecimal'
    model :shipping_costs, class: 'BigDecimal'

    def execute
      products = gather_order_products
      unique_products = get_unqiue_products(products) unless errors.any?
      compute_prices(unique_products) unless errors.any?
    end

    private

    # Within the gathering process, information about the products
    # along with weighted prices is send to the aggregating method
    # add_to_products
    # Optional and required parts' prices are separetely computed
    # to arrive at a more accurate allocation of the actual cost 
    # of each.
    def gather_order_products

      products = []

      order.line_items.physical.not_operational.each do |line|

        inventory_units = line.inventory_units.dup.to_a

        if line.parts.any?
          products << process_line_item_parts(line, inventory_units)
        else
          products << process_line_item(line, inventory_units)
        end

      end

      products.flatten

    end

    def variant_has_ignorable_product_type(variant)
      variant.product.product_type.is_operational? ||
      variant.product.product_type.is_digital?
    end


    def process_line_item(line, inventory_units)
      products = []
      inventory_units.each do |unit|
        products << {product: unit.variant.product,
                     price: unit.line_item.base_price,
                     supplier: unit.supplier }
      end
      products
    end

    def process_line_item_parts(line, inventory_units)
      products = []

      total_price_of_required_parts = line.parts.required.to_a.sum do |p| 
        p.price * p.quantity * line.quantity
      end
      proportion = ( line.base_price * line.quantity ) / total_price_of_required_parts

      line.quantity.times do
        line.parts.each do |part|
          part.quantity.times do

            index = inventory_units.index{|iu| iu.variant_id == part.variant_id }
            unit = inventory_units.slice!(index)

            next if variant_has_ignorable_product_type(unit.variant)

            if part.required?
              weighted_price =  part.price * proportion
              products << {product: unit.variant.product,
                           price: weighted_price,
                           supplier: unit.supplier }
            else
              products << {product: unit.variant.product,
                           price: part.price,
                           supplier: unit.supplier }
            end

          end
        end
      end
      products
    end

    def get_unqiue_products(order_products)
      order_products.inject({}) do |unique_products,order_product|

        product = order_product[:product]

        supplier = order_product[:supplier]
        unless supplier
          errors.add(:missing_supplier, "for product: #{product.name}")
          return
        end

        price = order_product[:price]

        key = [product.id, supplier.mid_code]

        if unique_products.has_key?(key)
          unique_products[key][:quantity] += 1
          unique_products[key][:total_price] += price
        else
          unique_products[key] = {
            product: product,
            group: product.product_group,
            quantity: 1,
            total_price: price,
            mid_code: supplier.mid_code,
            country: supplier.country
          }
        end

        unique_products

      end.values
    end

    def compute_prices(unique_products)
      unique_products = unique_products.dup

      total_price = unique_products.sum do |up|
        up[:total_price].to_f
      end
      order_total_without_shipping = order_total.to_f - shipping_costs.to_f

      proportion = order_total_without_shipping / total_price

      unique_products.map do |up|
        up[:total_price] = up[:total_price] * proportion
      end
      unique_products
    end

  end

end
