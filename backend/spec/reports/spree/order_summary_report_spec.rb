require 'spec_helper'

describe Spree::OrderSummaryReport do
  let(:report) { Spree::OrderSummaryReport.new({}) }

  let(:order) { create(:order) }
  #let(:order) { create(:completed_order_with_totals, line_items_count: 0) }

  let!(:marketing_type_1) { create(:marketing_type, name: 'woo')}
  let!(:marketing_type_2) { create(:marketing_type, name: 'foo')}
  let!(:marketing_type_3) { create(:marketing_type, name: 'part')}

  let(:product1) { create(:product, marketing_type: marketing_type_1)}
  let(:product2) { create(:product, marketing_type: marketing_type_1)}
  let(:product3) { create(:product, marketing_type: marketing_type_2)}
  let(:part)     { create(:product, marketing_type: marketing_type_3)}
  let(:line_item) { order.line_items.first}

  context "#marketing types" do
    before do
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

end


