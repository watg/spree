module Spree::Stock
  class OrderItemBuilder
    Item = Struct.new(:variant_id, :line_item, :quantity)

    attr_accessor :items, :line_items

    def initialize(line_items)
      @line_items = line_items
      @items      = build_items
    end

    def group_variants
      items.group_by(&:variant_id).map.inject({}) do |hash, (variant_id, units)|
        hash[variant_id] = units.sum(&:quantity)
        hash
      end
    end

    def find_by_variant_id(variant_id)
      items.select{ |item| item.variant_id == variant_id }
    end

    def variant_ids_for_line_item(line_item)
      items.select{ |item| item.line_item == line_item }.map(&:variant_id)
    end

  private

    def build_items
      line_items.uniq.map do |line_item|
        [build_item(line_item), build_items_from_parts(required_parts(line_item))]
      end.flatten.compact
    end

    def build_item(line_item)
      Item.new(line_item.variant_id, line_item, line_item.quantity) unless line_item.container?
    end

    def build_items_from_parts(parts)
      parts.map do |part|
        Item.new(part.variant_id, part.line_item, part.quantity * part.line_item.quantity)
      end
    end

    def required_parts(line_item)
      line_item.parts.reject(&:container?)
    end

  end
end
