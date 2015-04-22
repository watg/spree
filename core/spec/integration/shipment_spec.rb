require "spec_helper"

describe "user receives email" do
  let(:order)     { create(:order) }
  let(:shipment)  { create(:shipment, order: order) }
  let(:line_item) { create(:line_item, order: order) }
  let(:kit)       { create(:product_type, name: "kit") }

  before do
    line_item.product.product_type = kit
    shipment.state = "ready"
    allow(shipment).to receive_messages determine_state: "shipped"
    Timecop.freeze
  end

  context "kit and pattern survey email" do
    let(:handler) { YAML.load(Delayed::Job.last.handler).object }

    it "creates a delayed job for 1 month after today" do
      shipment.update!(order)
      expect(handler).to be_a(Shipping::KitAndPatternMailer)
      expect(Delayed::Job.last.run_at).to eq(1.month.from_now)
    end
  end
end
