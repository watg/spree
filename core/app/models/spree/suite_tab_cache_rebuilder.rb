module Spree
  class SuiteTabCacheRebuilder

    attr_accessor :suite_tab, :product, :suite, :target

    class << self

      def rebuild_from_variant(variant)
        variant.product.suite_tabs.map { |suite_tab| new(suite_tab).rebuild }
      end

      def rebuild_from_variant_async(variant)
        rebuild_from_variant(variant)
      end
      handle_asynchronously :rebuild_from_variant_async, :queue => 'cache', :priority => 10

    end

    def initialize(suite_tab)
      @suite_tab = suite_tab
      @product = suite_tab.product
      @suite = suite_tab.suite
      @target = suite.target
    end

    def rebuild(*options)
      rebuild_in_stock
      rebuild_lowest_amounts
      suite_tab.save
    end

    private

    def rebuild_in_stock
      suite_tab.in_stock_cache = variants_in_stock.any?
    end

    def rebuild_lowest_amounts
      prices = prices_for_variants_in_stock
      currencies = prices.map(&:currency).uniq
      currencies.each do |currency|

        if normal_price = find_lowest_normal_price(prices, currency)
          suite_tab.set_lowest_normal_amount(normal_price.amount, currency)
        end

        if sale_price = find_lowest_sale_price(prices, currency)
          suite_tab.set_lowest_sale_amount(sale_price.amount, currency)
          suite_tab.in_sale_cache = true
        else
          suite_tab.in_sale_cache = false
        end

      end
    end

    # Check the variants first, then if none exist check the master variant
    def variants_in_stock
      return @variants_in_stock if @variants_in_stock
      if product.variants.any?
        @variants_in_stock ||= product.variants_for(target).in_stock
      elsif product.master.in_stock_cache?
        @variants_in_stock ||= [product.master]
      else
        @variants_in_stock ||= []
      end
    end

    def prices_for_variants_in_stock
      variants_in_stock.map(&:prices).flatten
    end

    def find_lowest_normal_price(prices, currency)
      Spree::Price.find_normal_prices(prices, currency).sort_by(&:amount).first
    end

    def find_lowest_sale_price(prices, currency)
      Spree::Price.find_sale_prices(prices, currency).sort_by(&:amount).detect do |price|
        price.variant.in_sale?
      end
    end

  end
end

