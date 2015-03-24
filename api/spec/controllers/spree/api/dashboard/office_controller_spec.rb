require "spec_helper"
module Spree
  module Api
    module Dashboard
      describe OfficeController, type: :controller do
        render_views

        before do
          stub_authentication!
        end

        describe "#last_bought_product"  do
          it "should run the formatter" do
            expect(Office::FormatLastBoughtProduct).to receive(:new)
            api_get :last_bought_product
          end
          it "should run the formatter" do
            expect_any_instance_of(Office::FormatLastBoughtProduct).to receive(:run)
            api_get :last_bought_product
          end
        end

        describe "#today_sells"  do
          it "should run the formatter" do
            expect(Office::FormatTodaySells).to receive(:new)
            api_get :today_sells
          end
          it "should run the formatter" do
            expect_any_instance_of(Office::FormatTodaySells).to receive(:run)
            api_get :today_sells
          end
        end

        describe "#today_orders"  do
          it "should run the formatter" do
            expect(Office::FormatTodayOrders).to receive(:new)
            api_get :today_orders
          end
          it "should run the formatter" do
            expect_any_instance_of(Office::FormatTodayOrders).to receive(:run)
            api_get :today_orders
          end
        end

        describe "#today_items"  do
          it "should run the formatter" do
            expect(Office::FormatTodayItems).to receive(:new)
            api_get :today_items
          end
          it "should run the formatter" do
            expect_any_instance_of(Office::FormatTodayItems).to receive(:run)
            api_get :today_items
          end
        end

        describe "#today_sells_by_type"  do
          it "should run the formatter" do
            expect(Office::FormatTodaySellsByType).to receive(:new)
            api_get :today_sells_by_type
          end
          it "should run the formatter" do
            expect_any_instance_of(Office::FormatTodaySellsByType).to receive(:run)
            api_get :today_sells_by_type
          end
        end

        describe "#today_orders_by_hour"  do
          it "should run the formatter" do
            expect(Office::FormatTodayOrdersByHour).to receive(:new)
            api_get :today_orders_by_hour
          end
          it "should run the formatter" do
            expect_any_instance_of(Office::FormatTodayOrdersByHour).to receive(:run)
            api_get :today_orders_by_hour
          end
        end
      end
    end
  end
end
