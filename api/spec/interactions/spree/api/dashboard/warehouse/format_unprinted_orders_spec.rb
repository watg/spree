require "spec_helper"

describe Spree::Api::Dashboard::Warehouse::FormatUnprintedOrders, type: :interaction do
  let!(:unprinted_order) do
    create(:order,
           completed_at: Time.zone.now,
           invoice_print_job_id: nil,
           shipment_state: "ready",
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

  let!(:old_unprinted_order) do
    create(:order,
           completed_at: Time.zone.yesterday,
           invoice_print_job_id: nil,
           shipment_state: "ready",
           payment_state: "paid",
           state: "complete")
  end

  subject { described_class.new(Spree::Order.complete) }
  it "returns 1 new printed order" do
    expect(subject.run).to include(new: 1)
  end

  it "returns 1 old printed order" do
    expect(subject.run).to include(old: 1)
  end
end
