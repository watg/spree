module Spree
  class StockReport
    include BaseReport

    def initialize(params = nil)
    end

    def filename_uuid
      Time.now.to_s(:number)
    end

    def header
      header = %w(
        product_name
        product_type
        product_sku
        variant_sku
        variant_options
        cost_price
        GBP_normal
        GBP_part
        GBP_sale
        EUR_normal
        EUR_part
        EUR_sale
        USD_normal
        USD_part
        USD_sale
        stock_location
        on_hand_quantity
        waiting_for_shippment
        supplier_name
      )
    end

    def filters
      []
    end

    # Retrieve the stock that is in the warehouses
    def retrieve_data
      loop_stock_items do |stock_item|
        row = variant_details(stock_item.variant)
        row << stock_item.stock_location.name
        row << stock_item.count_on_hand
        row << stock_item.number_of_shipments_pending
        row << stock_item.supplier.try(:name)
        yield row
      end
    end

  private

    def loop_stock_items(&block)
      StockItem.joins(variant: [product: :product_type]).merge(ProductType.physical).find_each do |stock_item|
        yield stock_item
      end
    end

    def variant_details(variant)
      prices = variant.prices.map { |p| [[ p.currency, p.is_kit, p.sale ].join('-'), p.amount.to_s] }.flatten
      prices = Hash[*prices]
      [ 
        variant.product.name,
        variant.product.marketing_type.name,
        variant.product.sku,
        variant.sku,
        variant.option_values.empty? ? '' : variant.options_text,
        variant.cost_price,
        # Currency - kit? - sale ?
        prices['GBP-false-false'],
        prices['GBP-true-false'],
        prices['GBP-false-true'],
        prices['EUR-false-false'],
        prices['EUR-true-false'],
        prices['EUR-false-true'],
        prices['USD-false-false'],
        prices['USD-true-false'],
        prices['USD-false-true'],
      ] 
    end

  end
end
