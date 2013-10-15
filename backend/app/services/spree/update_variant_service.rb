module Spree
  class UpdateVariantService < Mutations::Command
    include ServiceTrait::Prices
    required do
      model :variant, class: 'Spree::Variant'

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
          string :label
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
