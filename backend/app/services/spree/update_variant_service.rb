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
          string :index_page_ids, empty: true
          string :tags, empty: true
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
      ActiveRecord::Base.transaction do
        tags = details.delete(:tags).split(",")
        details[:index_page_ids] = split_params(details[:index_page_ids])

        variant.update_attributes(details)
        update_prices(prices, variant)
        update_tags(variant, tags)
      end
    rescue Exception => e
      Rails.logger.error "[NewVariantService] #{e.message} -- #{e.backtrace}"
      add_error(:variant, :exception, e.message)
    end

    private

    def update_tags(variant, tag_names)
      tags = tag_names.map do |tag_name|
        Spree::Tag.find_or_create_by(value: tag_name)
      end
      variant.tags = tags
    end

    def split_params(input)
      input.blank? ? [] : input.split(',').map(&:to_i)
    end  

  end
end
