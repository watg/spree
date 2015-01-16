# -*- coding: utf-8 -*-
module Spree
  class Price < Spree::Base
    acts_as_paranoid
    belongs_to :variant, class_name: 'Spree::Variant', inverse_of: :prices, touch: true

    CURRENCY_SYMBOL = {'USD' => '$', 'GBP' => '£', 'EUR' => '€'}
    TYPES = [:normal,:normal_sale,:part,:part_sale]


    validate :check_price
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false
    validate :validate_amount_maximum

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
      self[:amount] = Spree::LocalizedNumber.parse(price)
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
      self.currency ||= Spree::Config[:currency]
    end

    def maximum_amount
      BigDecimal '999999.99'
    end

    def validate_amount_maximum
      if amount && amount > maximum_amount
        errors.add :amount, I18n.t('errors.messages.less_than_or_equal_to', count: maximum_amount)
      end
    end
  end
end
