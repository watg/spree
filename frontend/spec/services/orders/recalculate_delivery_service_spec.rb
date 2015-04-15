require "spec_helper"
describe Orders::RecalculateDeliveryService do
  let(:state) { "delivery" }
  let(:order) { mock_model(Spree::Order, state: state) }
  subject { described_class.run(order: order) }

  it "recalculates shipping if state is in delivery" do
    expect(order).to receive(:recalculate_shipping)
    expect(subject.valid?).to eq true
  end

  context "state is not in delivery" do
    let(:state) { "payment" }

    it "does not recaluate delivery" do
      expect(order).not_to receive(:recalculate_shipping)
      expect(subject.valid?).to eq true
    end
  end
end
