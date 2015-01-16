# encoding: utf-8
require 'money'

module Spree
  class Money
    attr_reader :money

    delegate :cents, to: :money

    cattr_accessor :options_cache

    cattr_accessor :enable_options_cache do
      true
    end

    def initialize(amount, options={})
      @money = Monetize.parse([amount, (options[:currency] || Spree::Config[:currency])].join)

      default_options = if enable_options_cache
                          self.class.options_cache ||= self.class.default_options
                        else
                          self.class.default_options
                        end

      @options = default_options.merge(options)

      @options[:symbol_position] = @options[:symbol_position].to_sym
    end

	def self.default_options
      {
        with_currency:       Spree::Config[:display_currency],
        symbol_position:     Spree::Config[:currency_symbol_position].to_sym,
        no_cents:            Spree::Config[:hide_cents],
        decimal_mark:        Spree::Config[:currency_decimal_mark],
        thousands_separator: Spree::Config[:currency_thousands_separator],
        sign_before_symbol:  Spree::Config[:currency_sign_before_symbol],
      }
    end

    def to_s
      @money.format(@options)
    end

    def to_html(options = { html: true })
      output = @money.format(@options.merge(options))
      if options[:html]
        # 1) prevent blank, breaking spaces
        # 2) prevent escaping of HTML character entities
        output = output.sub(" ", "&nbsp;").html_safe
      end
      output
    end

    def as_json(*)
      to_s
    end

    def ==(obj)
      @money == obj.money
    end

    def to_f
      @money.to_f
    end
  end
end
