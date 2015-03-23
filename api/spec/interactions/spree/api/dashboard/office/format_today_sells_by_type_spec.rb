require "spec_helper"

module Spree
  module Api
    module Dashboard
      module Office
        describe FormatTodaySellsByType, type: :interaction do
          let!(:marketing_pattern) { create(:marketing_type, title: "pattern") }
          let!(:marketing_kit) { create(:marketing_type, title: "kit") }
          let!(:normal) { create(:product_with_variants, marketing_type: marketing_pattern) }
          let!(:kit) { create(:product_with_variants, marketing_type: marketing_kit) }

          let!(:order) { create(:order, completed_at: Time.zone.now) }

          let!(:order_shipment) { create(:shipment, order: order, stock_location: create(:stock_location_with_items)) }

          let!(:li_1) { create_list(:line_item, 2, product: normal, order: order, quantity: 3) }
          let!(:li_2) { create_list(:line_item, 4, product: kit, order: order, quantity: 3) }

          subject { described_class.new(Order.complete) }
          describe "execute" do
            it "returns todays orders by currency" do
              allow_any_instance_of(Spree::Api::Dashboard::Office::FindTodayValidOrders).to receive(:run).and_return(Order.all)
              expect(subject.run).to eq([["kit", 12], ["pattern", 6]])
            end
          end
        end
      end
    end
  end
end
