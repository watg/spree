require "spec_helper"

describe Spree::OrderFormatter do
  let(:order) { create(:order) }
  subject { described_class.new(order) }

  describe "Initialization" do
    it "Sets up the @order variable" do
      expect(subject.instance_variable_get(:@order)).to eql(order)
    end
  end

  describe "Data Formatting" do
    subject { described_class.new(order).order_data }

    it { expect(subject).to have_key(:order_number) }
    it { expect(subject).to have_key(:email) }
    it { expect(subject).to have_key(:items) }
    it { expect(subject).to have_key(:items_total) }
    it { expect(subject).to have_key(:shipment_total) }
    it { expect(subject).to have_key(:adjustments) }
    it { expect(subject).to have_key(:promotions) }
    it { expect(subject).to have_key(:adjustments_total) }
    it { expect(subject).to have_key(:delivery_time) }
    it { expect(subject).to have_key(:currency) }
    it { expect(subject).to have_key(:payment_total) }
  end

  describe "items" do
    let(:item)    { create(:line_item) }
    let(:product) { item.product }
    let(:html) do
      "<tr>" \
      "<td align='left' style='font-weight:bold;'>#{product.name}</td>" \
      "<td align='left'>1</td><td align='left'></td>" \
      "<td align='left'>$10.00</td>" \
      "</tr>"
    end

    before { order.line_items = [item] }
    it     { expect(subject.order_data[:items]).to eq html }
  end

  describe "Data entries" do
    subject { described_class.new(order) }
    let!(:foo) { Spree::Adjustment.new(order: order, source_type: "Spree::PromotionAction", eligible: true, label: "foo", amount: 2) }

    before do
      allow_any_instance_of(Shipping::Coster).to receive_messages(final_price: 20, adjustment_total: -5)
      allow(order).to receive(:all_adjustments).and_return([foo])
    end

    describe "#shipment_total" do
      it "does something" do
        data = subject.order_data
        expect(data[:shipment_total]).to eq("$20.00")
        expect(data[:adjustments_total]).to eq("-$5.00")
        expect(data[:promotions]).to include(">$2.00<")
      end
    end
  end
end
