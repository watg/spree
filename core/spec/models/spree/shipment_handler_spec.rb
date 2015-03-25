require 'spec_helper'

RSpec.describe Spree::ShipmentHandler do
  let(:shipment) { create(:shipment) }
  subject(:handler) { described_class.new(shipment) }

  describe "#perform" do
    it "sends a post-shipment email" do
      shipment.send_email = true
      mailer = double(Spree::ShipmentMailer, deliver: true)
      expect(Spree::ShipmentMailer).to receive(:shipped_email).and_return(mailer)
      handler.perform
    end

    context "when the shipment prevents email sending" do
      it "does not send an email" do
        shipment.send_email = false
        expect(Spree::ShipmentMailer).not_to receive(:shipped_email)
        handler.perform
      end
    end
  end
end
