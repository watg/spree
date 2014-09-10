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
          invoice_services_data << format_grouped_inventory_unit(item)
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
        [ Spree::Variant.unscoped.find_by_id(iu.variant_id), iu.supplier]
      end
      grouped.map do |k,v|
        variant = k[0]
        supplier = k[1]
        is_part = ( variant == line.variant )? false : true
        { variant: variant, supplier: supplier, quantity: v.count, is_part: is_part }
      end
    end

    def format_kit_container(line)
      [
        "KIT - #{line.variant.product.name}",
        "#{line.variant.sku}",
        '',
        line.variant.option_values.empty? ? '' : line.variant.options_text,
        line.quantity,
        CHECKBOX
      ]
    end

    def format_grouped_inventory_unit(item)
      variant = item[:variant]
      supplier = " \n [#{item[:supplier].permalink}]" unless item[:supplier].is_company?
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
