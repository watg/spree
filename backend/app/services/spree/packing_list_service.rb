module Spree
  class PackingListService < ActiveInteraction::Base

    model :order, class: 'Spree::Order'

    CHECKBOX = '|_|'
    HEADER = [ 'item', 'SKU / [supplier_id]', 'contents', 'options', 'qty', '' ]

    def execute

      invoice_services_data = [ HEADER ]
      order.line_items.each do |line|

        # We want to show the container for the parts
        if line.parts.any?
          invoice_services_data << format_kit_container(line)
        end

        grouped_inventory_units(line).each do |item|
          invoice_services_data << format_grouped_inventory_unit(item, line)
        end

        line.line_item_personalisations.each do |p|
          invoice_services_data << format_personalisation(p)
        end

      end

      invoice_services_data

    end

    private

    def grouped_inventory_units(line)
      # TODO the methods below will help us format the picking list much better
      # line.parts.select { |p| p.parent_part.nil? }.map(&:variant).map(&:options_text).join(', '),
      #inventory_units = line.inventory_units.select { |i| !i.line_item_part.assembled or (i.line_item_part.assembled && i.line_item_part.main_part) }
      #grouped = inventory_units.group_by do |iu|
      grouped = line.inventory_units.group_by do |iu|
        [ Spree::Variant.unscoped.find(iu.variant_id), iu.supplier]
      end

      grouped_parts = grouped.map do |k,v|
        variant = k[0]
        supplier = k[1]
        is_part = ( variant == line.variant )? false : true
        next if line.parts.find { |part| (part.variant_id == variant.id) && (part.parent_part_id.present?) }

        { variant: variant, supplier: supplier, quantity: v.count, is_part: is_part }
      end.compact

      container_parts = line.parts.select { |part| part.container? }.map do |part|
        { variant: part.variant, supplier: nil, quantity: part.quantity, is_part: true }
      end

      grouped_parts + container_parts
    end

    def format_kit_container(line)
      if line.parts.assembled.any?
        item = "CUSTOM - " + line.variant.product.name
      else
        item = "KIT - " + line.variant.product.name
      end

      [
        item,
        "#{line.variant.sku}",
        '',
        line.variant.option_values.empty? ? '' : line.variant.options_text,
        line.quantity,
        CHECKBOX
      ]
    end

    def format_grouped_inventory_unit(item, line)
      variant = item[:variant]

      supplier = " \n [#{item[:supplier].permalink}]" if item[:supplier] and !item[:supplier].is_company?
      part = line.parts.find { |part| (part.variant_id == variant.id) }
      supplier = supplier.to_s + "\n Customize No: <b>#{part.id}</b>" if part && part.main_part? && part.assembled?

      quantity = item[:quantity]
      is_part = item[:is_part]
      item = is_part ? '' : variant.product.name
      content = is_part ? variant.product.name : ''

      [
        item,
        variant.sku + supplier.to_s,
        content,
        variant.option_values.empty? ? '' : variant.options_text,
        quantity,
        CHECKBOX
      ]
    end

    def format_personalisation(personalisation)
      [
        '',
        '',
        personalisation.name,
        personalisation.data_to_text,
        '',
        CHECKBOX
      ]
    end



  end
end
