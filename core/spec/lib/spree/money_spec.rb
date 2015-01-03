# coding: utf-8
require 'spec_helper'

describe Spree::Money do
  before do
    Spree::Money.enable_options_cache = false

    configure_spree_preferences do |config|
      config.currency = "USD"
      config.currency_symbol_position = :before
      config.display_currency = false
    end
  end

  context "enable_options_cache" do

    context "when disabled" do

      it "calls default_options on every initialize" do
        expect(Spree::Money).to receive(:default_options).twice.and_return(Spree::Money.default_options)
        Spree::Money.new(10)
        Spree::Money.new(10)
      end

    end

    context "when enabled" do

      before do
        Spree::Money.options_cache = nil 
        Spree::Money.enable_options_cache = true
      end

      it "calls default_options once" do
        expect(Spree::Money).to receive(:default_options).once.and_return(Spree::Money.default_options)
        Spree::Money.new(10)
        Spree::Money.new(10)
      end
    end

  end

  it "formats correctly" do
    money = Spree::Money.new(10)
    expect(money.to_s).to eq("$10.00")
  end

  it "can get cents" do
    money = Spree::Money.new(10)
    expect(money.cents).to eq(1000)
  end

  context "default_options" do

    it "returns the default options" do
      expect(described_class.default_options).to eq ( {
        with_currency: Spree::Config[:display_currency],
        symbol_position: Spree::Config[:currency_symbol_position].to_sym,
        no_cents:  Spree::Config[:hide_cents],
        decimal_mark:  Spree::Config[:currency_decimal_mark],
        thousands_separator: Spree::Config[:currency_thousands_separator],
        sign_before_symbol: Spree::Config[:currency_sign_before_symbol]
      })
    end

    it "calls default options as part of the initialize" do
      expect(described_class).to receive(:default_options).and_return(described_class.default_options)
      expect(described_class.new(10))
    end

  end

  context "with currency" do
    it "passed in option" do
      money = Spree::Money.new(10, :with_currency => true, :html => false)
      expect(money.to_s).to eq("$10.00 USD")
    end

    it "config option" do
      Spree::Config[:display_currency] = true
      money = Spree::Money.new(10, :html => false)
      expect(money.to_s).to eq("$10.00 USD")
    end
  end

  context "hide cents" do
    it "hides cents suffix" do
      Spree::Config[:hide_cents] = true
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("$10")
    end

    it "shows cents suffix" do
      Spree::Config[:hide_cents] = false
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("$10.00")
    end
  end

  context "currency parameter" do
    context "when currency is specified in Canadian Dollars" do
      it "uses the currency param over the global configuration" do
        money = Spree::Money.new(10, :currency => 'CAD', :with_currency => true, :html => false)
        expect(money.to_s).to eq("$10.00 CAD")
      end
    end

    context "when currency is specified in Japanese Yen" do
      it "uses the currency param over the global configuration" do
        money = Spree::Money.new(100, :currency => 'JPY', :html => false)
        expect(money.to_s).to eq("¥100")
      end
    end
  end

  context "symbol positioning" do
    it "passed in option" do
      money = Spree::Money.new(10, :symbol_position => :after, :html => false)
      expect(money.to_s).to eq("10.00 $")
    end

    it "passed in option string" do
      money = Spree::Money.new(10, :symbol_position => "after", :html => false)
      expect(money.to_s).to eq("10.00 $")
    end

    it "config option" do
      Spree::Config[:currency_symbol_position] = :after
      money = Spree::Money.new(10, :html => false)
      expect(money.to_s).to eq("10.00 $")
    end
  end

  context "sign before symbol" do
    it "defaults to -$10.00" do
      money = Spree::Money.new(-10)
      expect(money.to_s).to eq("-$10.00")
    end

    it "passed in option" do
      money = Spree::Money.new(-10, :sign_before_symbol => false)
      expect(money.to_s).to eq("$-10.00")
    end

    it "config option" do
      Spree::Config[:currency_sign_before_symbol] = false
      money = Spree::Money.new(-10)
      expect(money.to_s).to eq("$-10.00")
    end
  end

  context "JPY" do
    before do
      configure_spree_preferences do |config|
        config.currency = "JPY"
        config.currency_symbol_position = :before
        config.display_currency = false
      end
    end

    it "formats correctly" do
      money = Spree::Money.new(1000, :html => false)
      expect(money.to_s).to eq("¥1,000")
    end
  end

  context "EUR" do
    before do
      configure_spree_preferences do |config|
        config.currency = "EUR"
        config.currency_symbol_position = :after
        config.display_currency = false
      end
    end

    # Regression test for #2634
    it "formats as plain by default" do
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("10.00 €")
    end

    # Regression test for #2632
    it "acknowledges decimal mark option" do
      Spree::Config[:currency_decimal_mark] = ","
      money = Spree::Money.new(10)
      expect(money.to_s).to eq("10,00 €")
    end

    # Regression test for #2632
    it "acknowledges thousands separator option" do
      Spree::Config[:currency_thousands_separator] = "."
      money = Spree::Money.new(1000)
      expect(money.to_s).to eq("1.000.00 €")
    end

    it "formats as HTML if asked (nicely) to" do
      money = Spree::Money.new(10)
      # The HTML'ified version of "10.00 €"
      expect(money.to_html).to eq("10.00&nbsp;&#x20AC;")
    end

    it "formats as HTML with currency" do
      Spree::Config[:display_currency] = true
      money = Spree::Money.new(10)
      # The HTML'ified version of "10.00 €"
      expect(money.to_html).to eq("10.00&nbsp;&#x20AC; <span class=\"currency\">EUR</span>")
    end
  end

  describe "#as_json" do
    let(:options) { double('options') }

    it "returns the expected string" do
      money = Spree::Money.new(10)
      expect(money.as_json(options)).to eq("$10.00")
    end
  end

  describe ".parse" do
    subject { Spree::Money.parse input, currency  }

    context "when currency nil" do
      let(:currency) { nil }

      context "when input value is a number" do
        let(:input) { 42 }

        it { is_expected.to be_a ::Money }

        describe '#currency' do
          subject { super().currency }
          it { is_expected.to eq(::Money.default_currency) }
        end
      end
    end
  end

  describe "#as_json" do
    let(:options) { double('options') }

    it "returns the expected string" do
      money = Spree::Money.new(10)
      expect(money.as_json(options)).to eq("$10.00")
    end
  end

  describe ".parse" do
    subject { Spree::Money.parse input, currency  }

    context "when currency nil" do
      let(:currency) { nil }

      context "when input value is a number" do
        let(:input) { 42 }

        it { is_expected.to be_a ::Money }

        describe '#currency' do
          subject { super().currency }
          it { is_expected.to eq(::Money.default_currency) }
        end
      end
    end
  end
end
