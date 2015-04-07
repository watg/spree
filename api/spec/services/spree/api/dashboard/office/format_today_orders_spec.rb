require "spec_helper"

describe Spree::Api::Dashboard::Office::FormatTodayOrders, type: :interaction do
  let(:orders) { build_stubbed_list(:order, 3) }
  subject { described_class.new }
  describe "execute" do
    it "returns todays orders" do
      allow_any_instance_of(Spree::Api::Dashboard::Office::FindTodayValidOrders)
        .to receive(:run).and_return(orders)
      expect(subject.run).to eq(total: 3)
    end
  end
end
