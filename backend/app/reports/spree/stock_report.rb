module Spree
  class StockReport
    include BaseReport

    def initialize(params = nil)
      @locations = Spree::StockLocation.select("id, name") 
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
      )

      locations = []
      @locations.each do |l|
        locations << l.name
        locations << "waiting_for_shippment @" + l.name
      end

      header + locations + ['total']
    end

    def filters
      []
    end

    def xretrieve_data
      yield [1,2,3]
    end

    # Retrieve the stock that is in the warehouses
    def retrieve_data
      Spree::Variant.physical.each do |variant|
        row = variant_details(variant)

        count_on_location = {}
        variant.stock_items.each do |si|
          count_on_location[si.stock_location_id] = si.count_on_hand
        end
        
        total = 0
        
        @locations.map(&:id).each do |location_id|
          if count_on_location[location_id]
            total += count_on_location[location_id]
            row << count_on_location[location_id] # items at the location

            waiting_for_shippment = variant.line_items.joins(order: :shipments). #.select('spree_orders.*, spree_line_items.*').
            where('spree_orders.state' => :complete,
              'spree_orders.shipment_state' => :ready,
              'spree_orders.payment_state' => :paid,
              'spree_shipments.stock_location_id' => location_id).
            sum(:quantity)

            total += waiting_for_shippment
            row << waiting_for_shippment # items to be shipped at the location
          else
            row << 0 # items at the location
            row << 0 # items to be shipped at the location
          end
        end
      
        row << total
        yield row
      end
    end

  private

    def variant_details(variant)
      prices = variant.prices.map { |p| [[ p.currency, p.is_kit, p.sale ].join('-'), p.amount.to_s] }.flatten
      prices = Hash[*prices]
      [ 
        variant.product.name,
        variant.product.martin_type.name,
        variant.product.sku,
        variant.sku,
        variant.option_values.empty? ? '' : variant.options_text,
        variant.cost_price,
        # Currency - kit? - sale ?
        prices['GBP-false-false'],
        prices['GBP-true-false'],
        prices['GBP-true-true'],
        prices['EUR-false-false'],
        prices['EUR-true-false'],
        prices['EUR-true-true'],
        prices['USD-false-false'],
        prices['USD-true-false'],
        prices['USD-true-true'],
      ] 
    end

  end
end
