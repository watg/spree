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
          it "runs the formatter" do
            expect(::Api::Dashboard::Office::FormatLastBoughtProduct).
              to receive(:new)
            api_get :last_bought_product
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Office::FormatLastBoughtProduct).
              to receive(:run)
            api_get :last_bought_product
          end
        end

        describe "#today_sells"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Office::FormatTodaySells).
              to receive(:new)
            api_get :today_sells
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Office::FormatTodaySells).
              to receive(:run)
            api_get :today_sells
          end
        end

        describe "#today_orders"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Office::FormatTodayOrders).
              to receive(:new)
            api_get :today_orders
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Office::FormatTodayOrders).
              to receive(:run)
            api_get :today_orders
          end
        end

        describe "#today_items"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Office::FormatTodayItems).
              to receive(:new)
            api_get :today_items
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Office::FormatTodayItems).
              to receive(:run)
            api_get :today_items
          end
        end

        describe "#today_sells_by_type"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Office::FormatTodaySellsByType).
              to receive(:new)
            api_get :today_sells_by_type
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Office::FormatTodaySellsByType).
              to receive(:run)
            api_get :today_sells_by_type
          end
        end

        describe "#today_orders_by_hour"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Office::FormatTodayOrdersByHour).
              to receive(:new)
            api_get :today_orders_by_hour
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Office::FormatTodayOrdersByHour).
              to receive(:run)
            api_get :today_orders_by_hour
          end
        end
      end
    end
  end
end
