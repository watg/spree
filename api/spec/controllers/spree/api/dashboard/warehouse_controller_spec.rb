require "spec_helper"
module Spree
  module Api
    module Dashboard
      describe WarehouseController, type: :controller do
        render_views

        before do
          stub_authentication!
        end

        describe "#today_orders"  do
          it "should run the formatter" do
            expect(Warehouse::FormatTodayOrders).to receive(:new)
            api_get :today_orders
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatTodayOrders).to receive(:run)
            api_get :today_orders
          end
        end

        describe "#today_sells_by_marketing_type"  do
          it "should run the formatter" do
            expect(Warehouse::FormatTodaySellsByType).to receive(:new)
            api_get :today_sells_by_marketing_type
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatTodaySellsByType).to receive(:run)
            api_get :today_sells_by_marketing_type
          end
        end

        describe "#today_shipments"  do
          it "should run the formatter" do
            expect(Warehouse::FormatTodayShipments).to receive(:new)
            api_get :today_shipments
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatTodayShipments).to receive(:run)
            api_get :today_shipments
          end
        end

        describe "#printed_orders"  do
          it "should run the formatter" do
            expect(Warehouse::FormatPrintedOrders).to receive(:new)
            api_get :printed_orders
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatPrintedOrders).to receive(:run)
            api_get :printed_orders
          end
        end

        describe "#printed_by_marketing_type"  do
          it "should run the formatter" do
            expect(Warehouse::FormatPrintedItemsByType).to receive(:new)
            api_get :printed_by_marketing_type
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatPrintedItemsByType).to receive(:run)
            api_get :printed_by_marketing_type
          end
        end

        describe "#unprinted_orders"  do
          it "should run the formatter" do
            expect(Warehouse::FormatUnprintedOrders).to receive(:new)
            api_get :unprinted_orders
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatUnprintedOrders).to receive(:run)
            api_get :unprinted_orders
          end
        end

        describe "#unprinted_by_marketing_type"  do
          it "should run the formatter" do
            expect(Warehouse::FormatUnprintedItemsByType).to receive(:new)
            api_get :unprinted_by_marketing_type
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatUnprintedItemsByType).to receive(:run)
            api_get :unprinted_by_marketing_type
          end
        end

        describe "#unprinted_orders_waiting_feed"  do
          it "should run the formatter" do
            expect(Warehouse::FormatWaitingFeedOrders).to receive(:new)
            api_get :unprinted_orders_waiting_feed
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatWaitingFeedOrders).to receive(:run)
            api_get :unprinted_orders_waiting_feed
          end
        end

        describe "#waiting_feed_by_marketing_type"  do
          it "should run the formatter" do
            expect(Warehouse::FormatWaitingFeedByType).to receive(:new)
            api_get :waiting_feed_by_marketing_type
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatWaitingFeedByType).to receive(:run)
            api_get :waiting_feed_by_marketing_type
          end
        end

        describe "#today_shipments_by_country"  do
          it "should run the formatter" do
            expect(Warehouse::FormatTodayShipmentsByCountry).to receive(:new)
            api_get :today_shipments_by_country
          end
          it "should run the formatter" do
            expect_any_instance_of(Warehouse::FormatTodayShipmentsByCountry).to receive(:run)
            api_get :today_shipments_by_country
          end
        end
      end
    end
  end
end
