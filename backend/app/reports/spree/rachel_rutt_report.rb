module Spree
  class RachelRuttReport
    include BaseReport

    # Genereate new slugs
    #
    # Spree::IndexPage.where(permalink: "collections/rachel-rutt-x-watg").first.index_page_items.map(&:product_page).map(&:products).flatten.map(&:slug)
    #
    SLUGS = [
      "totally-tunic-36197664-4b25-407b-9520-8df292c8eed2",
      "totally-tunic",
      "primo-sweater-9a3dde40-36ec-4802-8251-e1834c338d55",
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
