require "spec_helper"
module Spree
  describe OrderSummaryReport do
    let(:report) { described_class.new({}) }

    describe "#retrieve_data" do
      subject do
        data = []
        described_class.new({}).retrieve_data { |d| data << d }
        data.flatten
      end

      it "runs fine without data (this tests the db lookup in #loop_orders)" do
        expect(subject).to eq []
      end

      context "with data" do
        let(:address) { build_stubbed(:address) }
        let(:marketing_type) { build_stubbed(:marketing_type) }
        let(:order_type) { build_stubbed(:regular_order_type) }
        let(:product) { Product.new(name: "Product 1", marketing_type: marketing_type) }
        let(:variant) { Variant.new(sku: "SKU1") }

        let(:order) do
          Spree::Order.new(
            bill_address: address,
            ship_address: address,
            order_type: order_type,
            total: 21.56,
            item_total: 19.45,
            shipment_total: 9.45
          )
        end

        before do
          product.variants << variant

          # stub out the db lookup
          allow_any_instance_of(described_class).to receive(:loop_orders).and_yield order
        end

        [:total, :shipment_total, :item_total].each do |method|
          it { is_expected.to include order.send(method) }
        end

        describe "adjustments" do
          let(:address) { create(:address) }
          let(:order) { create(:order, ship_address: address) }

          context "manual adjustment" do
            let(:manual_adjustment) { create(:adjustment, source: nil, amount: 4.31, order: order) }

            before do
              order.adjustments << manual_adjustment
            end

            it { is_expected.to include 4.31 }
          end
        end
      end
    end

    context "#marketing types" do
      let(:order) { create(:order) }
      let(:line_item) { order.line_items.first }

      let!(:marketing_type_1) { create(:marketing_type, name: "woo") }
      let!(:marketing_type_2) { create(:marketing_type, name: "foo") }
      let!(:marketing_type_3) { create(:marketing_type, name: "part") }

      let!(:product1) { create(:product, marketing_type: marketing_type_1) }
      let!(:product2) { create(:product, marketing_type: marketing_type_1) }
      let!(:product3) { create(:product, marketing_type: marketing_type_2) }
      let!(:part)     { create(:product, marketing_type: marketing_type_3) }

      before do
        product1.master.price_normal_in("USD").amount = 19.99
        product2.master.price_normal_in("USD").amount = 19.99
        product3.master.price_normal_in("USD").amount = 19.99
        order.contents.add(product1.master, 1)
        order.contents.add(product2.master, 1)
        order.contents.add(product3.master, 2)
      end

      it "returns marketing type headers" do
        header = report.marketing_type_headers
        expected = %w(woo_revenue_pre_promo foo_revenue_pre_promo part_revenue_pre_promo)
        expect(header).to eq expected
      end

      it "returns cumalitve totals" do
        totals = report.marketing_type_totals(order)
        expect(totals.map(&:to_s)).to eq(["39.98", "39.98", "0.0"])
      end

      it "returns cumalitve totals with parts" do
        create(:line_item_part, optional: true, line_item: line_item, variant: part.master)
        create(:line_item_part, optional: false, line_item: line_item, variant: part.master)
        totals = report.marketing_type_totals(order)
        expect(totals.map(&:to_s)).to eq(["44.97", "39.98", "0.0"])
      end
    end

    describe "order states" do
      let(:state_idx) { report.header.index("state") }
      let(:notes_idx) { report.header.index("latest_note") }

      describe "headers" do
        it "includes order states" do
          expect(state_idx).not_to be_nil
        end

        it "includes order notes" do
          expect(notes_idx).not_to be_nil
        end
      end

      describe "data" do
        let(:time_in_range) { Time.now.midnight + 1 }
        let!(:order) do
          create(:order_ready_to_ship, :with_marketing_type, completed_at: time_in_range)
        end

        it "includes order state" do
          processed = 0
          report.retrieve_data do |row|
            processed += 1
            expect(row[state_idx]).to eq(order.state)
          end
          expect(processed).to eq(1)
        end

        it "includes on hold orders" do
          create(:order_ready_to_ship, :with_marketing_type,
                 state: "warehouse_on_hold",
                 completed_at: time_in_range
                )
          create(:order_ready_to_ship, :with_marketing_type,
                 state: "customer_service_on_hold",
                 completed_at: time_in_range
                )
          processed = 0
          report.retrieve_data { processed += 1 }
          expect(processed).to eq(3)
        end

        it "includes the latest order note" do
          notes = create_list(:order_note, 2, order: order)

          processed = 0
          report.retrieve_data do |row|
            processed += 1
            expect(row[notes_idx]).to eq(notes.last.reason)
          end
          expect(processed).to eq(1)
        end
      end
    end

    describe "order types" do
      let(:order_type_idx) { report.header.index("order_type") }

      describe "headers" do
        it "includes order type field" do
          expect(order_type_idx).not_to be_nil
        end
      end

      describe "data" do
        let!(:regular) { create(:regular_order_type) }
        let!(:party) { create(:party_order_type) }

        let!(:regular_order) do
          create(:order_ready_to_ship, :with_marketing_type,
                 completed_at: Time.now,
                 order_type: regular)
        end
        let!(:party_order) do
          create(:order_ready_to_ship, :with_marketing_type,
                 completed_at: Time.now,
                 order_type: party
                )
        end
        it "includes regular orders" do
          order_types = []
          report.retrieve_data do |row|
            order_types << row[order_type_idx]
          end
          expect(order_types).to eq([regular.title, party.title])
        end
      end
    end

    describe "important orders" do
      let(:important_idx) { report.header.index("important") }

      describe "headers" do
        it "includes important field" do
          expect(important_idx).not_to be_nil
        end
      end

      describe "data" do
        let!(:important_order) do
          create(:order_ready_to_ship, :with_marketing_type,
                 completed_at: Time.now,
                 important: true
                )
        end
        let!(:unimportant_order) do
          create(:order_ready_to_ship, :with_marketing_type, completed_at: Time.now)
        end

        it "includes order important flag" do
          important_values = []
          report.retrieve_data do |row|
            important_values << row[important_idx]
          end
          expect(important_values).to eq([true, false])
        end
      end
    end
  end
end
