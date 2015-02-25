module Spree
  class TaraStilesReport
    include BaseReport

    SEARCH_NAMES ||= [
      "TS Hoodie",
      "Tree Hugger",
      "Hot Top",
      "Shakti Shorts",
      "Strala T-Shirt"
    ]

    attr_writer :search_names

    def initialize(params)
      @search_names = SEARCH_NAMES.map { |value| value.gsub(' ', '%') }
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
      for_each_order do |order|
        order.line_items.each do |line_item|
          product = line_item.product
          variant = line_item.variant

          if search_products.include?(product)
            yield [
              variant.name,
              variant.sku,
              line_item.currency,
              line_item.normal_price,
              line_item.price,
              order.completed_at,
              order.number
            ]
          end
        end
      end
    end

  private

    def for_each_order
      Spree::Order.where( :state => 'complete', :completed_at => @from..@to ).find_each do |order|
        yield order
      end
    end

    def search_products
      found_products = []
      @search_names.each do |name|
        found_products << Spree::Product.where("name ILIKE ?", '%' + name + '%')
      end
      found_products.flatten.uniq
    end


  end
end
