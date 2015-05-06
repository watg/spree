require "spec_helper"

describe Api::Dashboard::Office::FormatTodayOrdersByPriority, type: :interaction do
  let(:express_orders) { build_stubbed_list(:order, 3) }
  let(:regular_orders) { build_stubbed_list(:order, 7) }
  subject { described_class.new }
  describe "execute" do
    before do
      express_orders.each{ |e| allow(e).to receive(:express?).and_return(true)}
      regular_orders.each{ |r| allow(r).to receive(:express?).and_return(false)}
    end
    it "returns todays orders" do
      allow_any_instance_of(Api::Dashboard::Office::FindTodayValidOrders)
      .to receive(:run).and_return(express_orders.concat(regular_orders))
      expect(subject.run).to include(express: 3)
      expect(subject.run).to include(normal: 7)
    end
  end
end
