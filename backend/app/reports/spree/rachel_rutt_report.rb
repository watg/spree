module Spree
  class RachelRuttReport
    include BaseReport

    attr_writer :search_names

    NAMES = ['Totally Tunic',"Primo Sweater", "Teeny Tiny Bikini"]

    def search_variants
      Spree::Variant.unscoped.where( product_id: Spree::Product.unscoped.where(name: NAMES).map(&:id) ).flatten.uniq
    end

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

    def line_items
      Spree::LineItem.where(variant_id: search_variants.map(&:id)).merge(
        Spree::Order.complete.where(:completed_at => @from..@to)
      ).references(:order).includes(:order, :variant )
    end

    def retrieve_data
      line_items.find_each do |line_item|

        variant = line_item.variant
        o = line_item.order
        yield [variant.name, variant.sku, line_item.currency, line_item.normal_price, line_item.price, o.completed_at, o.number]
      end
    end

  end
end
