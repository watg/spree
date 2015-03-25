require "spec_helper"

describe Spree::Api::Dashboard::Warehouse::FormatWaitingFeedByType, type: :interaction do
  let!(:marketing_pattern) { create(:marketing_type, title: "pattern") }
  let!(:marketing_kit) { create(:marketing_type, title: "kit") }
  let!(:normal) { create(:product_with_variants, marketing_type: marketing_pattern) }
  let!(:kit) { create(:product_with_variants, marketing_type: marketing_kit) }

  let!(:printed_order) do
    create(:order,
           completed_at: Time.zone.now,
           invoice_print_job_id: 2,
           shipment_state: "ready",
           payment_state: "paid",
           state: "complete")
  end

  let!(:waiting_feed_by_marketing_type) do
    create(:order,
           completed_at: Time.zone.now,
           shipment_state: "awaiting_feed",
           payment_state: "paid",
           state: "complete")
  end

  let!(:printed_order_shipment) do
    create(:shipment,
           order: printed_order,
           stock_location: create(:stock_location_with_items))
  end

  let!(:waiting_feed_by_marketing_type_shipment) do
    create(:shipment,
           order: waiting_feed_by_marketing_type,
           stock_location: create(:stock_location_with_items))
  end

  # waiting line items
  let!(:waiting_li_1) do
    create(:line_item, quantity: 3, product: normal, order: waiting_feed_by_marketing_type)
  end
  let!(:waiting_li_2) { create(:line_item, product: kit, order: waiting_feed_by_marketing_type) }
  # printed line items
  let!(:printed_li_1) { create(:line_item, product: normal, order: printed_order) }
  let!(:printed_li_2) { create(:line_item, product: kit, order: printed_order) }

  subject { described_class.new(Spree::Order.complete) }
  describe "execute" do
    it "returns 3 patterns" do
      expect(subject.run.first).to eq(["pattern", 3])
    end

    it "returns 1 kit" do
      expect(subject.run.last).to eq(["kit", 1])
    end
  end
end
