require "spec_helper"

describe Spree::Api::Dashboard::Warehouse::FormatWaitingFeedOrders, type: :interaction do
  let!(:unprinted_orders_waiting_feed) do
    create(:order,
           completed_at: Time.zone.now,
           shipment_state: "awaiting_feed",
           payment_state: "paid",
           state: "complete")
  end

  let!(:printed_order) do
    create(:order,
           completed_at: Time.zone.now,
           invoice_print_job_id: 2,
           shipment_state: "ready",
           payment_state: "paid",
           state: "complete")
  end

  let!(:unprinted_order) do
    create(:order,
           completed_at: Time.zone.now,
           invoice_print_job_id: nil,
           shipment_state: "ready",
           payment_state: "paid",
           state: "complete")
  end

  let!(:old_unprinted_order_waiting_feed) do
    create(:order,
           completed_at: Time.zone.yesterday,
           shipment_state: "awaiting_feed",
           payment_state: "paid",
           state: "complete")
  end

  subject { described_class.new }
  it "returns 1 new printed order" do
    expect(subject.run).to include(new: 1)
  end

  it "returns 1 old printed order" do
    expect(subject.run).to include(old: 1)
  end
end
