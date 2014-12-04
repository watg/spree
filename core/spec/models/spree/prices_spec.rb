require 'spec_helper'

describe Spree::Price do
  let(:variant) { create(:variant)}
  let(:price) { variant.price_normal_in('USD') }

  context "touching" do
    it "should touch a variant" do
      price = variant.price_normal_in('USD')
      variant.update_column(:updated_at, 1.day.ago)
      price.touch
      variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end

  describe "#after_save" do
    before do
      Delayed::Worker.delay_jobs = false
    end
    after { Delayed::Worker.delay_jobs = true }

    context "trigger_suite_tab_cache_rebuilder" do
      it "gets called" do
        expect(price).to receive(:trigger_suite_tab_cache_rebuilder)
        price.save
      end
    end
  end

  context "trigger_suite_tab_cache_rebuilder" do

    it "calls the Spree::SuiteTabCacheRebuilder" do
      expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_variant_async).with(subject.variant)
      subject.send(:trigger_suite_tab_cache_rebuilder)
    end

  end

  context "Finding prices" do

    let(:normal_price) { mock_model(Spree::Price, is_kit: false, sale: false, currency: 'USD')}
    let(:normal_price_2) { mock_model(Spree::Price, is_kit: false, sale: false, currency: 'USD')}
    let(:sale_price) { mock_model(Spree::Price, is_kit: false, sale: true, currency: 'USD')}
    let(:sale_price_2) { mock_model(Spree::Price, is_kit: false, sale: true, currency: 'USD')}
    let(:part_price) { mock_model(Spree::Price, is_kit: true, sale: false, currency: 'USD')}
    let(:part_sale_price) { mock_model(Spree::Price, is_kit: true, sale: true, currency: 'USD')}
    let(:price_different_currency) { mock_model(Spree::Price, is_kit: false, sale: false, currency: 'GBP')}

    let(:prices) {[normal_price, normal_price_2, sale_price, sale_price_2, part_price, part_sale_price, price_different_currency]}

    it "returns the normal_prices" do
      expect(Spree::Price.find_normal_prices(prices, 'USD')).to eq [normal_price, normal_price_2]
    end

    it "returns the sale_prices" do
      expect(Spree::Price.find_sale_prices(prices, 'USD')).to eq [sale_price, sale_price_2]
    end

    it "only returns prices for the currency" do
      expect(Spree::Price.find_normal_prices(prices, 'GBP')).to eq [price_different_currency]
    end

    context "Finding a price" do
      it "returns the normal_prices" do
        expect(Spree::Price.find_normal_price(prices, 'USD')).to eq normal_price
      end

      it "returns the sale_prices" do
        expect(Spree::Price.find_sale_price(prices, 'USD')).to eq sale_price
      end
    end
  end

  context ".default_price" do
    it "should return default price" do
      expected = {
        "id"=>nil,
        "variant_id"=>nil,
        "amount"=> BigDecimal.new('0.0'),
        "currency"=>"USD",
        "is_kit"=>false,
        "sale"=>false,
        "deleted_at"=>nil
      }
      expect(Spree::Price.default_price.attributes).to eq expected
    end
  end

  context "money" do
    let!(:price) { Spree::Price.new( amount: 123, currency: 'USD') }

    it "returns the money version of a price" do
      expect(price.money).to eq Spree::Money.new(123, currency: 'USD')
    end

    context "class method" do
      it "returns the money version of a price" do
        expect(described_class.money(123, 'USD')).to eq Spree::Money.new(123, currency: 'USD')
      end
    end
  end


  context "validates_uniqueness_of" do
    # Choose the GBP currency as variant has a default price with USD
    let(:price) { build(:price, currency: 'GBP',variant: variant) }
    let(:dup_price) { build(:price, currency: 'GBP', variant: variant) }

    it "should not allow duplicate prices" do
      expect(price.valid?).to be_true
      price.save
      expect(dup_price.valid?).to be_false
    end
  end

end
