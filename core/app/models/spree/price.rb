# -*- coding: utf-8 -*-
module Spree
  class Price < ActiveRecord::Base
    acts_as_paranoid

    CURRENCY_SYMBOL = {'USD' => '$', 'GBP' => '£', 'EUR' => '€'}
    TYPES = [:normal,:normal_sale,:part,:part_sale]

    belongs_to :variant, class_name: 'Spree::Variant', inverse_of: :prices, touch: true

    validate :check_price
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false

    after_save :trigger_suite_tab_cache_rebuilder

    # Prevent duplicate prices from happening in the system, there is also a uniq
    # index on the database table to ensure there are no race conditions
    validates_uniqueness_of :variant_id, :scope => [ :currency, :sale, :is_kit, :deleted_at ]

    class << self

      def money(amount, currency)
        Spree::Money.new(amount || 0, { currency: currency })
      end

      def default_price
        new(amount: 0, currency: Spree::Config[:currency], sale: false, is_kit: false)
      end

      def find_normal_prices(prices, currency=nil)
        prices = prices.select{ |price| price.sale == false && price.is_kit == false }
        prices = prices.select{ |price| price.currency == currency } if currency
        prices
      end

      def find_normal_price(prices, currency=nil)
        find_normal_prices(prices, currency).first
      end

      def find_sale_prices(prices, currency=nil)
        prices = prices.select{ |price| price.sale == true && price.is_kit == false }
        prices = prices.select{ |price| price.currency == currency } if currency
        prices
      end

      def find_sale_price(prices, currency=nil)
        find_sale_prices(prices, currency).first
      end

      def find_part_price(prices, currency)
        prices.select{ |price| price.currency == currency && price.sale == false && price.is_kit == true }.first
      end

      def find_part_sale_price(prices, currency)
        prices.select{ |price| price.currency == currency && price.sale == true && price.is_kit == true }.first
      end
    end

    def display_amount
      money
    end

    alias :display_price :display_amount

    def money
      self.class.money(amount,currency)
    end

    def price
      amount
    end

    def in_subunit
      ( (price || 0) * 100 ).to_i
    end

    def currency_symbol
      CURRENCY_SYMBOL[currency.to_s.upcase]
    end

    def price=(price)
      self[:amount] = parse_price(price)
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { super }
    end

  private

    def trigger_suite_tab_cache_rebuilder
      Spree::SuiteTabCacheRebuilder.rebuild_from_variant_async(self.variant)
    end

    def check_price
      raise "Price must belong to a variant" if variant.nil?

      if currency.nil?
        self.currency = Spree::Config[:currency]
      end
    end

    def parse_price(price)
      self.class.parse_price(price)
    end

    # strips all non-price-like characters from the price, taking into account locale settings
    def self.parse_price(price)
      return price unless price.is_a?(String)

      separator, delimiter = I18n.t([:'number.currency.format.separator', :'number.currency.format.delimiter'])
      non_price_characters = /[^0-9\-#{separator}]/
      price.gsub!(non_price_characters, '') # strip everything else first
      price.gsub!(separator, '.') unless separator == '.' # then replace the locale-specific decimal separator with the standard separator if necessary

      price.to_d
    end
  end
end
