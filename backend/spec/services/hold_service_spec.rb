require 'spec_helper'

describe Spree::HoldService do
  let(:user) { create(:user) }
  let(:order) { create(:order, state: "complete") }
  let(:reason) { "the reason we have to put it on hold" }
  let(:type) { "warehouse" }
  let(:params) { {order: order, reason: reason, user: user, type: type} }

  subject(:service) { Spree::HoldService }

  it "is valid" do
    expect(service.run(params)).to be_valid
  end

  it "creates a note from the reason" do
    expect { service.run(params) }.to change(Spree::OrderNote, :count).by(1)
    note = Spree::OrderNote.last
    expect(note.order).to eq(order)
    expect(note.user).to eq(user)
    expect(note.reason).to eq(reason)
  end

  context "when the type is warehouse" do
    it "sets the order status to 'warehouse_on_hold'" do
      service.run(params)
      expect(order.reload).to be_warehouse_on_hold
    end

    it "sends an email to customer services" do
      message = <<-END
Order #{order.number} has been put on hold by the warehouse:

#{reason}

http://www.example.com/admin/orders/#{order.number}/edit
      END

      delayable = double("delay")
      expect(Spree::NotificationMailer).to receive(:delay).and_return(delayable)
      expect(delayable).to receive(:send_notification).
        with(message,
        ["test+order-hold@woolandthegang.com"],
        "Order #{order.number} put on hold")
      service.run(params)
    end
  end

  context "when the type is customer_service" do
    let(:type) { "customer_service" }

    it "sets the order status to 'customer_service_on_hold'" do
      service.run(params)
      expect(order.reload).to be_customer_service_on_hold
    end

    it "doesn't send an email" do
      expect(Spree::NotificationMailer).not_to receive(:send_notification)
      service.run(params)
    end
  end
end
