require 'spec_helper'

describe Spree::Price do
  let(:variant) { create(:variant)}
  let(:price) { variant.price_normal_in('USD') }

  context "touching" do
    it "should touch a variant" do
      price = variant.price_normal_in('USD')
      variant.update_column(:updated_at, 1.day.ago)
      price.touch
      expect(variant.reload.updated_at).to be_within(3.seconds).of(Time.now)
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
    let(:normal_price) { build(:price, sale_amount: sale_amount, part_amount: part_amount, currency: 'USD') }
    let(:sale_amount)  { 50.0 }
    let(:part_amount)  { 60.0 }
    let(:uk_price)     { build(:price, currency: 'GBP') }

    let(:prices) { [normal_price, uk_price] }

    describe '.find_normal_prices' do
      it { expect(Spree::Price.find_normal_prices(prices, 'USD')).to eq [normal_price] }
      it { expect(Spree::Price.find_normal_prices(prices, 'GBP')).to eq [uk_price] }
    end

    describe '.find_sale_prices' do
      it { expect(Spree::Price.find_sale_prices(prices, 'USD').first.amount).to eq sale_amount }
    end

    describe '.find_normal_price' do
      it { expect(Spree::Price.find_normal_price(prices, 'USD')).to eq normal_price }
    end

    describe '.find_sale_price' do
      it { expect(Spree::Price.find_sale_price(prices, 'USD').amount).to eq sale_amount }
    end

    describe '.find_part_price' do
      it { expect(Spree::Price.find_part_price(prices, 'USD').amount).to eq part_amount }
    end
  end

  describe ".default_price" do
    let(:expected) {
                     {
                       "id"=>nil,
                       "variant_id"=>nil,
                       "amount"=> BigDecimal.new('0.0'),
                       "currency"=>"USD",
                       "is_kit"=>false,
                       "sale"=>false,
                       "deleted_at"=>nil,
                       "sale_amount" => BigDecimal.new('0.0'),
                       "part_amount" => BigDecimal.new('0.0'),
                       "new_format" => true
                     }
                  }
    it { expect(Spree::Price.default_price.attributes).to eq expected }
  end

  describe "#money" do
    let(:price) { Spree::Price.new( amount: 123, currency: 'USD') }
    it { expect(price.money).to eq Spree::Money.new(123, currency: 'USD') }
  end

  describe '.money' do
    it { expect(described_class.money(123, 'USD')).to eq Spree::Money.new(123, currency: 'USD') }
  end

  context "validates_uniqueness_of" do
    # Choose the GBP currency as variant has a default price with USD
    let(:price)     { build(:price, currency: 'GBP',variant: variant) }
    let(:dup_price) { build(:price, currency: 'GBP', variant: variant) }

    it "should not allow duplicate prices" do
      expect(price.valid?).to be true
      price.save
      expect(dup_price.valid?).to be false
    end
  end

end
