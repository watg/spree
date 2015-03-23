require "spec_helper"

module Spree
  module Api
    module Dashboard
      module Office
        describe FormatTodayItems, type: :interaction do
          let!(:orders) { create_list(:order, 3) }
          let!(:line_items) { create_list(:line_item, 3, quantity: 2, order: orders[0]) }
          subject { described_class.new(Order.complete) }
          describe "execute" do
            it "returns todays items" do
              allow_any_instance_of(Spree::Api::Dashboard::Office::FindTodayValidOrders).to receive(:run).and_return(Order.all)
              expect(subject.run).to eq(total: 6)
            end
          end
        end
      end
    end
  end
end
