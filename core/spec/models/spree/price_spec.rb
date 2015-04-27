require "spec_helper"

describe Spree::Price, type: :model do
  let(:gbp)      { build(:price, currency: "GBP") }
  let(:eur)      { build(:price, currency: "EUR") }
  let(:prices)   { [usd, gbp, eur] }

  describe '.find_normal_prices' do
    let(:usd)      { build(:price, amount: 10.00) }
    let(:usd2)     { build(:price, amount: 20.00) }
    let(:prices)   { [usd, usd2, gbp, eur] }
    let(:expected) { described_class.find_normal_prices(prices, 'USD') }

    it { expect(expected).to eq([usd, usd2]) }
  end

  describe '.find_normal_price' do
    let(:usd)      { build(:price, amount: 10.00) }
    let(:expected) { described_class.find_normal_price(prices, 'USD') }

    it { expect(expected).to eq(usd) }
    it { expect(expected).to_not be_readonly }

    context 'price doesnt exist' do
      let(:expected) { described_class.find_normal_price(prices, 'none') }
      it { expect(expected).to be nil }
    end
  end

  describe '.find_sale_prices' do
    let(:usd)      { build(:price, sale_amount: 10.00) }
    let(:usd2)     { build(:price, sale_amount: 20.00) }
    let(:prices)   { [usd, usd2, gbp, eur] }
    let(:expected) { described_class.find_sale_prices(prices, 'USD') }

    it { expect(expected).to eq([usd, usd2]) }
  end

  describe '.find_sale_price' do
    let(:usd)      { build(:price, sale_amount: 10.00) }
    let(:expected) { described_class.find_sale_price(prices, 'USD') }

    it { expect(expected).to eq(usd) }
    it { expect(expected.amount).to eq 10.00}
  end

  describe '.find_part_price' do
    let(:usd)      { build(:price, part_amount: 10.00) }
    let(:expected) { described_class.find_part_price(prices, 'USD') }

    it { expect(expected).to eq(usd) }
    it { expect(expected.amount).to eq 10.00}

    context 'price doesnt exist' do
      let(:expected) { described_class.find_part_price(prices, 'none') }
      it { expect(expected).to be nil }
    end
  end

  describe ".find_by_currency" do
    let(:usd)    { build(:price, currency: "USD") }
    let(:gbp)    { build(:price, currency: "GBP") }
    let(:eur)    { build(:price, currency: "EUR") }
    let(:prices) { [usd, gbp, eur] }

    it { expect(described_class.find_by_currency(prices, "USD")).to eq(usd) }
  end

  describe "validations" do
    let(:variant) { stub_model Spree::Variant }
    subject { described_class.new variant: variant, amount: amount }


    context "when the amount is less than 0" do
      let(:amount) { -1 }

      it "has 1 error_on" do
        expect(subject.error_on(:amount).size).to eq(1)
      end
      it "populates errors" do
        subject.valid?
        expect(subject.errors.messages[:amount].first).to eq "must be greater than or equal to 0"
      end
    end

    context "when the amount is greater than 999,999.99" do
      let(:amount) { 1_000_000 }
      let(:error_message) { "must be less than or equal to 999999.99" }
      it "has 1 error_on" do
        expect(subject.error_on(:amount).size).to eq(1)
      end
      it "populates errors" do
        subject.valid?
        expect(subject.errors.messages[:amount].first).to eq error_message
      end
    end

    context "when the amount is between 0 and 999,999.99" do
      let(:amount) { 100 }
      it { is_expected.to be_valid }
    end
  end
end
