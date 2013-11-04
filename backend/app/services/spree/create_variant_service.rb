module Spree
  class CreateVariantService < Mutations::Command
    include ServiceTrait::Prices
    required do
      model :product, class: 'Spree::Product'
      hash :details do
        required do
          string :sku
          array :option_value_ids do
            string
          end 
        end

        optional do
          float :height
          float :depth
          float :width
          float :weight
          string :label, nils: true, empty: true
          integer :part_id
        end

      end

      hash :prices do
        required do
          duck :normal
          duck :normal_sale
        end

        optional do
          duck :part
          duck :part_sale
        end
      end
    end

    def execute
      variant = Spree::Variant.new( product_id: product.id )
      ActiveRecord::Base.transaction do
        variant.update_attributes(details)
        update_prices(prices, variant)
      end
    rescue Exception => e
      Rails.logger.error "[NewVariantService] #{e.message} -- #{e.backtrace}"
      add_error(:variant, :exception, e.message)
    end

  end
end
