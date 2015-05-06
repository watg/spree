require "spec_helper"
module Spree
  module Api
    module Dashboard
      describe WarehouseController, type: :controller do
        render_views

        before do
          stub_authentication!
        end

        describe "#today_orders_by_priority"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatTodayOrdersByPriority).
              to receive(:new)
            api_get :today_orders_by_priority
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatTodayOrdersByPriority).
              to receive(:run)
            api_get :today_orders_by_priority
          end
        end

        describe "#today_sells_by_marketing_type"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatTodaySellsByType).
              to receive(:new)
            api_get :today_sells_by_marketing_type
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatTodaySellsByType).
              to receive(:run)
            api_get :today_sells_by_marketing_type
          end
        end

        describe "#today_shipments_by_priority"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatTodayShipmentsByPriority).
              to receive(:new)
            api_get :today_shipments_by_priority
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatTodayShipmentsByPriority).
              to receive(:run)
            api_get :today_shipments_by_priority
          end
        end

        describe "#printed_orders"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatPrintedOrders).
              to receive(:new)
            api_get :printed_orders
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatPrintedOrders).
              to receive(:run)
            api_get :printed_orders
          end
        end

        describe "#printed_by_marketing_type"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatPrintedItemsByType).
              to receive(:new)
            api_get :printed_by_marketing_type
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatPrintedItemsByType).
              to receive(:run)
            api_get :printed_by_marketing_type
          end
        end

        describe "#unprinted_orders"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatUnprintedOrders).
              to receive(:new)
            api_get :unprinted_orders
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatUnprintedOrders).
              to receive(:run)
            api_get :unprinted_orders
          end
        end

        describe "#unprinted_by_marketing_type"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatUnprintedItemsByType).
              to receive(:new)
            api_get :unprinted_by_marketing_type
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatUnprintedItemsByType).
              to receive(:run)
            api_get :unprinted_by_marketing_type
          end
        end

        describe "#unprinted_orders_waiting_feed"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatWaitingFeedOrders).
              to receive(:new)
            api_get :unprinted_orders_waiting_feed
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatWaitingFeedOrders).
              to receive(:run)
            api_get :unprinted_orders_waiting_feed
          end
        end

        describe "#waiting_feed_by_marketing_type"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatWaitingFeedByType).
              to receive(:new)
            api_get :waiting_feed_by_marketing_type
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatWaitingFeedByType).
              to receive(:run)
            api_get :waiting_feed_by_marketing_type
          end
        end

        describe "#today_shipments_by_country"  do
          it "runs the formatter" do
            expect(::Api::Dashboard::Warehouse::FormatTodayShipmentsByCountry).
              to receive(:new)
            api_get :today_shipments_by_country
          end
          it "runs the formatter" do
            expect_any_instance_of(::Api::Dashboard::Warehouse::FormatTodayShipmentsByCountry).
              to receive(:run)
            api_get :today_shipments_by_country
          end
        end
      end
    end
  end
end
