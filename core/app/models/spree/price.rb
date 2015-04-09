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
    #validates_uniqueness_of :variant_id, :scope => [ :currency, :sale, :is_kit, :deleted_at ]
    validates_uniqueness_of :variant_id, :scope => [ :currency, :deleted_at ]

    class << self

      def money(amount, currency)
        Spree::Money.new(amount || 0, { currency: currency })
      end

      def default_price
        new(amount: 0, currency: Spree::Config[:currency], sale: false, is_kit: false)
      end

      def find_normal_prices(prices, currency=nil)
        prices.map do |p|
          find_normal_price([p], currency)
        end.compact
      end

      def find_normal_price(prices, currency=nil)
        price = find_by_currency(prices, currency)
        price.readonly! if price
        price
      end

      def find_sale_prices(prices, currency=nil)
        prices.map do |p|
          find_sale_price([p], currency)
        end.compact
      end

      def find_sale_price(prices, currency=nil)
        price = find_by_currency(prices,currency)
        return unless price
        price.amount = price.sale_amount
        price.readonly!
        price
      end

      def find_part_price(prices, currency)
        price = find_by_currency(prices,currency)
        return unless price
        price.amount = price.part_amount
        price.readonly!
        price
      end

      def find_by_currency(prices,currency)
        prices.detect{|price| price.currency == currency }
      end
    end

    def display_amount
      money(amount)
    end

    def display_sale_amount
      money(sale_amount)
    end

    def display_part_amount
      money(part_amount)
    end

    alias :display_price :display_amount

    def money(amount)
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
