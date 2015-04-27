require "spec_helper"
describe Spree::PricePresenter do
  subject { described_class.new(price, view) }

  let(:price)  { create(:price, prices.merge(currency: "USD", variant_id: 1)) }

  describe "#display_amount" do
    let(:prices) { { amount: 10.00 } }
    it "formats the amount price" do
      expect(Spree::Price).to receive(:money).with(price.amount, price.currency)
      subject.display_amount
    end
  end

  describe "#display_sale_amount"do
    let(:prices) { { sale_amount: 20.00 } }
    it "formats the amount price" do
      expect(Spree::Price).to receive(:money).with(price.sale_amount, price.currency)
      subject.display_sale_amount
    end
  end

  describe "#display_part_amount" do
    let(:prices) { { part_amount: 30.00 } }
    it "formats the amount price" do
      expect(Spree::Price).to receive(:money).with(price.part_amount, price.currency)
      subject.display_part_amount
    end
  end
end
