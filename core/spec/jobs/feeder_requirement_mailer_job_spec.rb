require 'spec_helper'

describe Spree::FeederRequirementMailerJob do
  let(:planner) { Spree::Feed::Planner.new }
  let(:plan) { {} }

  subject(:job) { Spree::FeederRequirementMailerJob.new }

  before do
    allow(Spree::Feed::Planner).to receive(:new).and_return(planner)
    allow(planner).to receive(:plan).and_return(plan)
  end

  describe "#perform" do
    it "creates a plan" do
      job.perform
      expect(Spree::Feed::Planner).to have_received(:new).with(Spree::Feed::InventoryUnitRequirement, Spree::Feed::StockThresholdRequirement)
    end

    context "when there is stock to move from the feeder" do
      let(:london) { create(:stock_location, name: "London") }
      let(:bray) { create(:stock_location, name: "Bray") }
      let(:lima) { create(:stock_location, name: "Lima") }
      let(:variant1) { create(:variant, sku: "sku1") }
      let(:variant2) { create(:variant, sku: "sku2") }
      let(:plan) {{
        london => {
          bray => { variant1 => 2, variant2 => 1 },
          lima => { variant1 => 3 },
        }
      }}

      it "send an email" do
        message = <<-END
Bray -> London
  2 of sku1
  1 of sku2

Lima -> London
  3 of sku1

        END

        deliverable = double("mailer", deliver: true)

        expect(Spree::NotificationMailer).to receive(:send_notification).
          with(message,
          ["test+feeder-requirements@woolandthegang.com"],
          "Stock movement required").
          and_return(deliverable)
        job.perform

        expect(deliverable).to have_received(:deliver)
      end
    end

    context "when there is no stock to move from the feeder" do
      let(:plan) {{}}

      it "does not send an email" do
        expect(Spree::NotificationMailer).not_to receive(:send_notification)
        job.perform
      end
    end
  end
end
