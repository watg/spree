require "spec_helper"
require "ruby-debug"
module Spree
  describe Api::WarehouseDashboardController, type: :controller do
    render_views

    before do
      stub_authentication!
    end

    describe "#today_orders" do
      let!(:whole_sale_order) { create(:order, completed_at: Time.zone.now) }
      let!(:normal_order_1) { create(:order, completed_at: Time.zone.now) }
      let!(:normal_order_2) { create(:order, completed_at: Time.zone.now) }
      let!(:old_order) { create(:order, completed_at: Time.zone.yesterday) }
      it "returns 3 orders" do
        api_get :today_orders
        expect(json_response["total"]).to eq(3)
      end
    end

    describe "#today_shippments" do
      let!(:shipped_shipments) { create_list(:shipment , 4, state: 'shipped', shipped_at: Time.zone.now ) }
      let!(:old_shipped_shipments) { create_list(:shipment , 4, state: 'shipped', shipped_at: Time.zone.yesterday ) }
      let!(:unshipped_shipments) { create_list(:shipment , 4, state: 'pending') }

      it "returns 3 shippments" do
        api_get :today_shipments
        expect(json_response["total"]).to eq(4)
      end
    end

    describe "#printed_orders" do
      let!(:printed_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: 2, shipment_state: "ready", payment_state: "paid") }
      let!(:unprinted_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: nil, shipment_state: "ready", payment_state: "paid") }
      let!(:old_printed_order) { create(:order, completed_at: Time.zone.yesterday, invoice_print_job_id: 3, shipment_state: "ready", payment_state: "paid") }

      it "returns 1 new printed order" do
        api_get :printed_orders
        expect(json_response["new"]).to eq(1)
      end

      it "returns 1 old printed order" do
        api_get :printed_orders
        expect(json_response["old"]).to eq(1)
      end
    end

    describe "#unprinted_orders" do
      let!(:unprinted_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: nil, shipment_state: "ready", payment_state: "paid") }
      let!(:printed_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: 2, shipment_state: "ready", payment_state: "paid") }
      let!(:old_unprinted_order) { create(:order, completed_at: Time.zone.yesterday, invoice_print_job_id: nil, shipment_state: "ready", payment_state: "paid") }

      it "returns 1 new unprinted order" do
        api_get :unprinted_orders
        expect(json_response["new"]).to eq(1)
      end

      it "returns 1 old unprinted order" do
        api_get :unprinted_orders
        expect(json_response["old"]).to eq(1)
      end
    end

    describe "#unprinted_orders_waiting_feed" do
      let!(:unprinted_orders_waiting_feed) { create(:order, completed_at: Time.zone.now, shipment_state: "awaiting_feed", payment_state: "paid") }
      let!(:printed_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: 2, shipment_state: "ready", payment_state: "paid") }
      let!(:unprinted_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: nil, shipment_state: "ready", payment_state: "paid") }
      let!(:old_unprinted_order_waiting_feed) { create(:order, completed_at: Time.zone.yesterday, shipment_state: "awaiting_feed", payment_state: "paid") }

      it "returns 1 new unprinted order" do
        api_get :unprinted_orders_waiting_feed
        expect(json_response["new"]).to eq(1)
      end

      it "returns 1 old unprinted order" do
        api_get :unprinted_orders_waiting_feed
        expect(json_response["old"]).to eq(1)
      end
    end

    context "orders by marketing type" do
      let!(:marketing_pattern) { create(:marketing_type, title: "pattern") }
      let!(:marketing_kit) { create(:marketing_type, title: "kit") }
      let!(:normal) { create(:product_with_variants, marketing_type: marketing_pattern) }
      let!(:kit) { create(:product_with_variants, marketing_type: marketing_kit) }

      describe "#printed_by_marketing_type" do
        let!(:printed_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: 2, shipment_state: "ready", payment_state: "paid") }
        let!(:unprinted_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: nil, shipment_state: "ready", payment_state: "paid") }
        let!(:printed_order_shipment) { create(:shipment, order: printed_order, stock_location: create(:stock_location_with_items)) }
        let!(:unprinted_order_shipment) { create(:shipment, order: unprinted_order, stock_location: create(:stock_location_with_items)) }

        # printed line items
        let!(:printed_li_1) { create(:line_item, quantity: 3, product: normal, order: printed_order) }
        let!(:printed_li_2) { create(:line_item, product: kit, order: printed_order) }

        # unprinted line items
        let!(:unprinted_li_1) { create(:line_item, product: normal, order: unprinted_order) }
        let!(:unprinted_li_2) { create(:line_item, product: kit, order: unprinted_order) }

        it "returns 2 marketing_types" do
          api_get :printed_by_marketing_type
          expect(json_response.size).to eq(2)
        end

        it "returns 3 patterns" do
          api_get :printed_by_marketing_type
          expect(json_response.first).to eq(["pattern",3])
        end
        it "returns 1 kit" do
          api_get :printed_by_marketing_type
          expect(json_response.last).to eq(["kit",1])
        end
      end

      describe "#unprinted_by_marketing_type" do
        let!(:printed_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: 2, shipment_state: "ready", payment_state: "paid") }
        let!(:unprinted_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: nil, shipment_state: "ready", payment_state: "paid") }
        let!(:printed_order_shipment) { create(:shipment, order: printed_order, stock_location: create(:stock_location_with_items)) }
        let!(:unprinted_order_shipment) { create(:shipment, order: unprinted_order, stock_location: create(:stock_location_with_items)) }

        # unprinted line items

        let!(:unprinted_li_1) { create(:line_item, quantity: 3, product: normal, order: unprinted_order) }
        let!(:unprinted_li_2) { create(:line_item, product: kit, order: unprinted_order) }
        # printed line items
        let!(:printed_li_1) { create(:line_item, product: normal, order: printed_order) }
        let!(:printed_li_2) { create(:line_item, product: kit, order: printed_order) }

        it "returns 2 marketing_types" do
          api_get :unprinted_by_marketing_type
          expect(json_response.size).to eq(2)
        end

        it "returns 3 patterns" do
          api_get :unprinted_by_marketing_type
          expect(json_response.first).to eq(["pattern",3])
        end
        it "returns 1 kit" do
          api_get :unprinted_by_marketing_type
          expect(json_response.last).to eq(["kit",1])
        end
      end

      describe "#waiting_feed_by_marketing_type" do
        let!(:printed_order) { create(:order, completed_at: Time.zone.now, invoice_print_job_id: 2, shipment_state: "ready", payment_state: "paid") }
        let!(:waiting_feed_by_marketing_type) { create(:order, completed_at: Time.zone.now, shipment_state: "awaiting_feed", payment_state: "paid") }
        let!(:printed_order_shipment) { create(:shipment, order: printed_order, stock_location: create(:stock_location_with_items)) }
        let!(:waiting_feed_by_marketing_type_shipment) { create(:shipment, order: waiting_feed_by_marketing_type, stock_location: create(:stock_location_with_items)) }

        # waiting line items
        let!(:waiting_li_1) { create(:line_item, quantity: 3, product: normal, order: waiting_feed_by_marketing_type) }
        let!(:waiting_li_2) { create(:line_item, product: kit, order: waiting_feed_by_marketing_type) }
        # printed line items
        let!(:printed_li_1) { create(:line_item, product: normal, order: printed_order) }
        let!(:printed_li_2) { create(:line_item, product: kit, order: printed_order) }

        it "returns 2 marketing_types" do
          api_get :waiting_feed_by_marketing_type
          expect(json_response.size).to eq(2)
        end

        it "returns 3 patterns" do
          api_get :waiting_feed_by_marketing_type
          expect(json_response.first).to eq(["pattern",3])
        end
        it "returns 1 kit" do
          api_get :waiting_feed_by_marketing_type
          expect(json_response.last).to eq(["kit",1])
        end
      end

      describe "#today_shipments_by_country" do
        let!(:address) {create(:address)}
        let!(:shipment1) { create(:shipment ,state: 'shipped', shipped_at: Time.zone.now , address: address) }
        let!(:shipment2) { create(:shipment ,state: 'shipped', shipped_at: Time.zone.now  , address: address) }

        it "it should return the quantity of shipped orders by location" do
          api_get :today_shipments_by_country
          expect(json_response.first).to eq([address.country.name,2])
        end
      end
    end
  end
end
