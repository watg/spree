module Spree
  class StockReport
    include BaseReport

    FILTERS = [] 

    HEADER = %w(
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

    def initialize(params)
      @locations = Set.new 
      @variant_stock_count = {}
      @variants = {}
    end

    def filename_uuid
      Time.now.to_s(:number)
    end

    
    def header
      HEADER
      HEADER + @locations.to_a + ['total']
    end

    def filters
      FILTERS
    end

    def xretrieve_data
      yield [1,2,3]
    end

    def retrieve_data

      Spree::Variant.joins(:product,:stock_items).each do |variant| 
        variant.stock_items.each do |si|
          @variant_stock_count[variant.sku] ||= {} 
          @variant_stock_count[variant.sku][si.stock_location.name] ||= 0 
          @variant_stock_count[variant.sku][si.stock_location.name] += si.count_on_hand 

          @locations << si.stock_location.name
          @variants[variant.sku] = variant_details(variant)
        end
      end

      @locations << 'waiting_for_shippment'
      Spree::LineItem.joins(:order).where(
        "completed_at IS NOT NULL and shipment_state not in ('partial', 'shipped') ").sum(:quantity, :group => :variant_id ).each do |v,c| 
          variant = Spree::Variant.unscoped.find(v) 
          @variant_stock_count[variant.sku] ||= {} 
          @variant_stock_count[variant.sku]['waiting_for_shippment'] ||= 0 
          @variant_stock_count[variant.sku]['waiting_for_shippment'] += c 
          @variants[variant.sku] = variant_details(variant)
        end

        @variant_stock_count.each do |sku,locations_count|

          data = @variants[sku]
          total = 0
          @locations.each do |location|
            if locations_count[location] 
              data << locations_count[location] 
              total += locations_count[location]
            else
              data << 0
            end
          end
          data << total
          yield data 
        end
    end

    private

    def variant_details(variant)
      prices = variant.prices.map { |p| [[ p.currency, p.is_kit, p.sale ].join('-'), p.amount.to_s] }.flatten
      prices = Hash[*prices]
      [ 
        variant.product.name,
        product_type(variant),
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

    def product_type(variant)

      if ['kit','virtual_product'].include? variant.product_type 
        variant.product_type
      else
        if variant.sku.match(/^GANG-/)
          'gang_collection'
        else
          if variant.isa_part?
            'part'
          else
            'ready_to_wear'
          end
        end

      end

    end

  end

end
