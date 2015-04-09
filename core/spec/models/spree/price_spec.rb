require "spec_helper"

describe Spree::Price, type: :model do
  describe "validations" do
    let(:variant) { stub_model Spree::Variant }
    subject { described_class.new variant: variant, amount: amount }

    # Disabled as in our case price amount should never be nil
    # context 'when the amount is nil' do
    #  let(:amount) { nil }
    #  it { is_expected.to be_valid }
    # end

    describe ".find_by_currency" do
      let(:usd)    { build(:price, currency: "USD") }
      let(:gbp)    { build(:price, currency: "GBP") }
      let(:eur)    { build(:price, currency: "EUR") }
      let(:prices) { [usd, gbp, eur] }
      it "returns the price by currency" do
        expect(described_class.find_by_currency(prices, "USD")).to eq(usd)
      end
    end

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
