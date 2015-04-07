require "spec_helper"
describe Spree::Api::Dashboard::Warehouse::FindTodayValidOrders, type: :interaction do
  let!(:new_valid_orders) { create_list(:order, 3, completed_at: Time.zone.now) }
  let!(:old_valid_orders) { create_list(:order, 5, completed_at: Time.zone.yesterday) }
  subject { described_class.new(Spree::Order.all) }

  describe "execute" do
    it "it should return only todays valid orders" do
      expect(subject.run).to include(new_valid_orders[0])
      expect(subject.run).to include(new_valid_orders[1])
      expect(subject.run).to include(new_valid_orders[2])
    end
    it "it should not old valid orders" do
      expect(subject.run).not_to include(old_valid_orders[0])
      expect(subject.run).not_to include(old_valid_orders[1])
      expect(subject.run).not_to include(old_valid_orders[2])
    end
  end
end
