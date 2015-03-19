require 'spec_helper'

RSpec.describe Admin::Orders::UpdateShipmentEmailOnOrder do
  describe "execute" do
    let(:shipments) { build_list(:shipment, 2) }
    let(:order) { create(:order, shipments: shipments) }

    subject(:updater) { described_class }

    context "when state is true" do
      it "enables the email on all of the order's shipments" do
        shipments.each do |s|
          s.update_attributes(send_email: false)
        end
        updater.run(order: order, state: true)
        expect(order.shipments.reload.map(&:send_email?).uniq).to match_array([true])
      end
    end

    context "when the state is false" do
      it "disables the email on all of the order's shipments" do
        updater.run(order: order, state: false)
        expect(order.shipments.reload.map(&:send_email?).uniq).to match_array([false])
      end
    end
  end
end
