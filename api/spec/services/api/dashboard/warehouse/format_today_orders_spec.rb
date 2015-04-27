require "spec_helper"

describe Api::Dashboard::Warehouse::FormatTodayOrders, type: :interaction do
  let(:orders) { build_stubbed_list(:order, 3, state: "complete") }
  subject { described_class.new }
  describe "execute" do
    it "returns todays orders" do
      allow_any_instance_of(Api::Dashboard::Warehouse::FindTodayValidOrders)
        .to receive(:run).and_return(orders)
      expect(subject.run).to eq(total: 3)
    end
  end
end
