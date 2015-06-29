require "spec_helper"
describe Orders::PopulateService do
  let(:order) { create(:order) }
  let(:line_item) { mock_model(Spree::LineItem) }
  subject { described_class.run(order: order, params: params) }

  let(:variant) { create(:base_variant, amount: 60.00) }
  let(:quantity) { 2 }
  let(:target_id) { 45 }
  let(:suite_id) { 1 }
  let(:options) { {} }

  let(:params) do
    {
      variant_id: variant.id,
      quantity: quantity,
      target_id: target_id,
      suite_tab_id: 2,
      suite_id: suite_id,
      options: options
    }
  end

  let!(:order_contents_options) do
    {
      target_id: target_id,
      suite_tab_id: 2,
      suite_id: suite_id
    }
  end

  let(:order_contents) { Spree::OrderContents.new(order) }

  before do
    allow(order).to receive(:contents).and_return(order_contents)
  end

  context "when populating the order" do
    let(:shipment) { build(:shipment) }

    before do
      order.shipments << shipment
    end

    it "returns a populate item and updates shipment" do
      expect(order_contents).to receive(:add).with(variant, 2, order_contents_options)
        .and_return(line_item)
      expect(subject.valid?).to eq true
      expect(subject.result).to_not be_nil
      expect(subject.result.variant).to eq variant
      expect(subject.result.quantity).to eq quantity
      expect(order.shipments).to be_empty
    end
  end

  context "no options" do
    let(:order) { build_stubbed(:order) }

    let(:params) do
      {
        variant_id: variant.id,
        quantity: quantity,
        target_id: target_id,
        suite_tab_id: 2,
        suite_id: suite_id
      }
    end

    let!(:order_contents_options) do
      {
        target_id: target_id,
        suite_tab_id: 2,
        suite_id: suite_id
      }
    end

    it "still populates" do
      expect(order_contents).to receive(:add).with(variant, 2, order_contents_options)
        .and_return(line_item)
      expect(subject.valid?).to eq true
    end
  end

  context "no target" do
    let(:order) { build_stubbed(:order) }
    let(:target_id) { "" }

    let!(:order_contents_options) do
      {
        target_id: nil,
        suite_tab_id: 2,
        suite_id: suite_id
      }
    end

    it "still populates" do
      expect(order_contents).to receive(:add).with(variant, 2, order_contents_options)
        .and_return(line_item)
      expect(subject.valid?).to eq true
    end
  end

  context "with error" do
    let(:order) { build_stubbed(:order) }
    let(:suite_id) { nil }

    it "still populates" do
      expect(order_contents).to_not receive(:add)
      outcome = subject
      expect(outcome.valid?).to be_falsey
      string = "Params has an invalid nested value (\"suite_id\" => nil)"
      expect(outcome.errors.full_messages.join(" ")).to eq string
    end
  end
end
