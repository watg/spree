module Spree
  class StockItemSupplierService < ActiveInteraction::Base

    model :variant, class: 'Spree::Variant'
    string :supplier_id, default: nil

    def execute

      if requires_supplier(variant)
        supplier = Supplier.where(id: supplier_id).first
        if supplier.nil?
          errors.add(:supplier, 'is required')
        else
          supplier
        end
      else
        nil
      end

    end

    private

    def requires_supplier(variant)
      variant.product.product_type.requires_supplier?
    end

  end

end
