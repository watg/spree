module Spree::Stock
  class OrderItemBuilder
    Item = Struct.new(:variant_id, :line_item, :quantity)

    attr_accessor :items, :line_items

    def initialize(line_items)
      @line_items = line_items
      @items = []
      build_items
    end

    def group_variants
      hash = {}
      items.group_by(&:variant_id).map do |variant_id, units|
        hash[variant_id] = units.sum(&:quantity)
      end
      hash
    end

    def find_by_variant_id(variant_id)
      items.select { |item| item.variant_id == variant_id }
    end

    def variant_ids_for_line_item(line_item)
      items.select { |item| item.line_item == line_item }.map(&:variant_id)
    end

  private

    def build_items
      line_items.uniq.each do |line_item|
        build_item(line_item)
      end
    end

    def build_item(line_item)
      parts = line_item.parts.select {|part| !part.container? }

      if parts.any?
        parts.each do |part|
          @items << Item.new(part.variant_id, line_item, part.quantity * line_item.quantity)
        end
      else
        @items << Item.new(line_item.variant_id, line_item, line_item.quantity)
      end
    end


  end
end
