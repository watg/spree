require "spec_helper"

describe Api::Dashboard::Warehouse::FormatUnprintedOrders, type: :interaction do
  let!(:unprinted_order) do
    create(:order,
           completed_at: Time.zone.now,
           invoice_print_job_id: nil,
           shipment_state: "ready",
           internal: false,
           batch_invoice_print_date: nil,
           payment_state: "paid",
           state: "complete"
    )
  end

  let!(:printed_order) do
    create(:order,
           completed_at: Time.zone.now,
           invoice_print_job_id: 2,
           batch_invoice_print_date: Time.zone.now,
           shipment_state: "ready",
           internal: false,
           payment_state: "paid",
           state: "complete")
  end

  let!(:old_unprinted_order) do
    create(:order,
           completed_at: Time.zone.yesterday,
           invoice_print_job_id: nil,
           shipment_state: "ready",
           batch_invoice_print_date: nil,
           internal: false,
           payment_state: "paid",
           state: "complete")
  end

  let(:physical_line_item) do
    OpenStruct.new(
    variant: OpenStruct.new(
    product:  OpenStruct.new(
    product_type: OpenStruct.new(
    is_digital: false)
    )
    )
    )
  end

  before do
    allow_any_instance_of(Spree::Order).to receive(:line_items).and_return([physical_line_item])
  end
  subject { described_class.new }
  it "returns 1 new printed order" do
    expect(subject.run).to include(new: 1)
  end

  it "returns 1 old printed order" do
    expect(subject.run).to include(old: 1)
  end
end
