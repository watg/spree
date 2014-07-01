module Spree
  class RachelRuttReport
    include BaseReport

    SLUGS = [
      "totally-tunic",
      "primo-sweater",
      "breezy-bathers",
      "teeny-tiny-bikini",
      "tubular-skirt"
    ]

    attr_writer :search_names

    def initialize(params)
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])  
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])  
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      %w(
        name
        sku
        currency
        normal_price
        sale_price
        completed_at
        order_number
      )
    end

    def retrieve_data
      Spree::Order.where( :state => 'complete', :completed_at => @from..@to ).find_each do |o| 
        o.line_items.each do |line_item|
          variant = line_item.variant
          if search_variants.include?(variant)
            yield [variant.name, variant.sku, line_item.currency, line_item.normal_price, line_item.price, o.completed_at, o.number]
          end
        end
      end
    end

    private

    def search_variants
      found_products = []
      SLUGS.each do |name|
        found_products << Spree::Product.where(slug: name)
      end
      found_products.empty? ? [] : found_products.flatten.uniq.map(&:variants).flatten
    end

  end
end
