require "spec_helper"

describe Api::Dashboard::Warehouse::FormatPrintedOrders, type: :interaction do
  let!(:printed_order) do
    create(:order,
           completed_at: Time.zone.now,
           batch_invoice_print_date: Time.zone.now,
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

  let!(:old_printed_order) do
    create(:order,
           completed_at: Time.zone.yesterday,
           batch_invoice_print_date: Time.zone.yesterday,
           invoice_print_job_id: 3,
           shipment_state: "ready",
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
