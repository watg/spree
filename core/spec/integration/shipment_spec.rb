require "spec_helper"

describe "user receives email" do
  let(:order)     { create(:order) }
  let(:shipment)  { create(:shipment, order: order) }
  let(:line_item) { create(:line_item, order: order) }
  let(:kit)       { create(:product_type, name: "kit") }

  before do
    product = line_item.product
    product.product_type = kit
    product.save
    shipment.state = "ready"
    allow(shipment).to receive_messages determine_state: "shipped"
  end

  context "kit and pattern survey email" do
    it "creates a delayed job for 1 month after today" do
      Timecop.freeze
      shipment.update!(order)
      expect(Delayed::Job.last.handler).to include("KitAndPatternEmailSurveyJob")
      expect(Delayed::Job.last.run_at).to eq(1.month.from_now)
    end
  end
end
