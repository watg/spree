require 'spec_helper'

describe Spree::TaraStilesReport do
  let(:report) { Spree::TaraStilesReport.new({}) }

  context "#retrieve_data" do
    
    it "should return zero rows with no ILIKE match" do
      order = create(:completed_order_with_totals, line_items_count: 1)
      report.search_names = ["non-existing-product"]
      report.retrieve_data do |data| 
        expect(data).to eq nil
      end
    end
    
    it "should return one row" do
      order = create(:completed_order_with_totals, line_items_count: 1)
      report.search_names = order.products.map(&:name)
      
      data = []
      report.retrieve_data do |d|
        data << d
      end
      expect(data).to eq [row(order.line_items.first)]
    end
    
    it "should return two rows" do
      order = create(:completed_order_with_totals, line_items_count: 2)
      report.search_names = order.products.map(&:name)
      
      data = []
      report.retrieve_data do |d| 
        data << d
      end
      data.should =~ [row(order.line_items.first), row(order.line_items.second)]
    end

    def row(line)
      [line.variant.name, line.variant.sku, line.currency, line.normal_price, line.price, line.order.completed_at, line.order.number]  
    end

  end
end


