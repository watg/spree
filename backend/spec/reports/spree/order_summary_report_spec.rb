require 'spec_helper'

describe Spree::OrderSummaryReport do
  let(:report) { Spree::OrderSummaryReport.new({}) }

  let(:order) { create(:order) }
  #let(:order) { create(:completed_order_with_totals, line_items_count: 0) }

  let!(:marketing_type_1) { create(:marketing_type, name: 'woo')}
  let!(:marketing_type_2) { create(:marketing_type, name: 'foo')}
  let!(:marketing_type_3) { create(:marketing_type, name: 'part')}

  let!(:product1) { create(:product, marketing_type: marketing_type_1)}
  let!(:product2) { create(:product, marketing_type: marketing_type_1)}
  let!(:product3) { create(:product, marketing_type: marketing_type_2)}
  let!(:part)     { create(:product, marketing_type: marketing_type_3)}
  let(:line_item) { order.line_items.first}

  context "#marketing types" do
    before do
      product1.master.price_normal_in('USD').amount = 19.99
      product2.master.price_normal_in('USD').amount = 19.99
      product3.master.price_normal_in('USD').amount = 19.99
      order.contents.add(product1.master, 1)
      order.contents.add(product2.master, 1)
      order.contents.add(product3.master, 2)
    end

    it "should return marketing type headers" do
      header = report.marketing_type_headers
      header.should == ["woo_revenue_pre_promo", "foo_revenue_pre_promo", "part_revenue_pre_promo"]
    end

    it "should return cumalitve totals" do
      totals = report.marketing_type_totals(order)
      totals.map(&:to_s).should == [ '39.98', '39.98', '0.0' ]
    end

    it "should return cumalitve totals with parts" do
      create(:line_item_part, optional: true, line_item: line_item, variant: part.master)
      create(:line_item_part, optional: false, line_item: line_item, variant: part.master)
      totals = report.marketing_type_totals(order)
      totals.map(&:to_s).should == [ '44.97', '39.98', '0.0' ]
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
      let!(:order) { create(:order_ready_to_ship, completed_at: time_in_range) }

      it "includes order state" do
        processed = 0
        report.retrieve_data do |row|
          processed += 1
          expect(row[state_idx]).to eq(order.state)
        end
        expect(processed).to eq(1)
      end

      it "includes on hold orders" do
        create(:order_ready_to_ship, state: "warehouse_on_hold", completed_at: time_in_range)
        create(:order_ready_to_ship, state: "customer_service_on_hold", completed_at: time_in_range)
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
end


