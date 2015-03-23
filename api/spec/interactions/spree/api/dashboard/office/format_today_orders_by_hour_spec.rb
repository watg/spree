require "spec_helper"

module Spree
  module Api
    module Dashboard
      module Office
        describe FormatTodayOrdersByHour, type: :interaction do
          let!(:orders_early) { create_list(:order, 4, completed_at: Time.zone.now.at_beginning_of_day) }
          let!(:orders_recent) { create_list(:order, 4, completed_at: 1.hour.ago) }
          subject { described_class.new(Order.complete) }

          describe "execute" do
            it "contains all the hours until one hour ago" do
              allow_any_instance_of(Spree::Api::Dashboard::Office::FindTodayValidOrders).to receive(:run).and_return(Order.all)
              expect(subject.run.count).to eq(Time.zone.now.hour)
            end

            it "orders should be complete last hour" do
              allow_any_instance_of(Spree::Api::Dashboard::Office::FindTodayValidOrders).to receive(:run).and_return(Order.all)
              expect(subject.run[1.hour.ago.hour][:y]).to eq(4)
            end
          end
        end
      end
    end
  end
end
