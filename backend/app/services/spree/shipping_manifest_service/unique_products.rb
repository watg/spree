module Spree
  class ShippingManifestService::UniqueProducts < ActiveInteraction::Base
    model :order, class: "Spree::Order"
    model :order_total, class: "BigDecimal"
    model :shipping_costs, class: "BigDecimal"

    def execute
      product_units = order.line_items.physical.not_operational.flat_map do |line|
        line_units, part_units = partition_units(line)
        build_product_units(line_units, part_units)
      end

      validate_product_units(product_units)
      grouped_product_units = group_product_units(product_units) unless errors.any?
      compute_prices(grouped_product_units) unless errors.any?
    end

    private

    def partition_units(line)
      line_units, part_units = line.inventory_units.partition { |iu| !iu.line_item_part }
      if line.variant.product.assemble?
        # Use the first assembly_defintion_part for the line unit if it is not defined
        line_units = first_part_units(line, part_units) unless line_units.any?
        part_units = []
      end
      [line_units, part_units]
    end

    def first_part_units(line, part_units)
      first_adp = line.product.product_parts.sort_by(&:position).first
      part_units.select do |pu|
        pu.line_item_part.assembly_definition_part == first_adp
      end
    end

    def validate_product_units(product_units)
      missing_supplier_unit = product_units.detect { |pu| pu.supplier.nil? }
      return unless missing_supplier_unit
      product = missing_supplier_unit.product
      errors.add(:missing_supplier,
                 "for product: #{product.name} (ID: #{product.id}) for order ##{order.number}")
    end

    def group_product_units(units)
      grouped_units = units.group_by { |u| [u.product, u.supplier.mid_code, u.supplier.country] }
      grouped_units.map do |(product, mid_code, country), product_units|
        {
          product: product,
          group: product.product_group,
          quantity: product_units.size,
          total_price: product_units.sum(&:price),
          mid_code: mid_code,
          country: country
        }
      end
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

    def invalid_product_type(inventory_unit)
      product_type = inventory_unit.variant.product.product_type
      product_type.is_operational? || product_type.is_digital?
    end

    ProductUnit  = Struct.new(:product, :price, :optional, :supplier)
    def build_product_units(line_units, part_units)
      products = line_units.map do |unit|
        ProductUnit.new(
          unit.variant.product,
          unit.line_item.base_price,
          false,
          unit.supplier
        )
      end

      products += part_units.reject { |u| invalid_product_type(u) }.map do |unit|
        ProductUnit.new(
          unit.variant.product,
          unit.line_item_part.price,
          unit.line_item_part.optional?,
          unit.supplier
        )
      end

      products
    end
  end
end
