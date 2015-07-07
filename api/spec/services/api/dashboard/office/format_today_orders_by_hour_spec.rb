require "spec_helper"

describe Api::Dashboard::Office::FormatTodayOrdersByHour, type: :interaction do

  subject { described_class.new }
  describe "execute" do
    before do
      new_time = Time.local(2015, 9, 1, 12, 0, 0)
      Timecop.freeze(new_time)
      orders_early = create_list(:order, 4, completed_at: Time.zone.now.at_beginning_of_day)
      orders_recent = create_list(:order, 4, completed_at: 1.hour.ago)
    end
    it "contains all the hours until one hour ago" do
      allow_any_instance_of(Api::Dashboard::Office::FindTodayValidOrders)
        .to receive(:run).and_return(Spree::Order.all)
      expect(subject.run.count).to eq(Time.zone.now.hour)
    end

    it "orders should be complete last hour" do
      allow_any_instance_of(Api::Dashboard::Office::FindTodayValidOrders)
        .to receive(:run).and_return(Spree::Order.all)
      expect(subject.run[1.hour.ago.hour][:y]).to eq(4)
    end
  end
end
