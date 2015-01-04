require 'spec_helper'

describe Spree::StockReport do
  let(:report) { Spree::StockReport.new }

  context "#header" do
    it "should return the correct header with no stock locations configured" do
      report.header.should == ["product_name", "product_type", "product_sku", "variant_sku", "variant_options", "cost_price", "GBP_normal", "GBP_part", "GBP_sale", "EUR_normal", "EUR_part", "EUR_sale", "USD_normal", "USD_part", "USD_sale", "total"] 
    end

    it "should return the correct header with stock locations configured" do
      location = FactoryGirl.create(:stock_location)
      report.header.should == ["product_name", "product_type", "product_sku", "variant_sku", "variant_options", "cost_price", "GBP_normal", "GBP_part", "GBP_sale", "EUR_normal", "EUR_part", "EUR_sale", "USD_normal", "USD_part", "USD_sale", location.name, "waiting_for_shippment @" + location.name, "total"] 
    end
  end

  context "#retrieve_data" do
    before { pending }

    xit "should return no data if none exists" do
      report.retrieve_data.should == []
    end

    xit "should return one row when creating a master product" do
      p = FactoryGirl.create(:product_with_stock) # stock is 10 items
      
      row = [p.name, "ready_to_wear", p.sku, p.sku, "", nil, nil, nil, nil, nil, nil, nil, "12.0", nil, nil, 10, 0, 10]
      report.retrieve_data do |data| 
        data.should == row
      end
    end
    
    xit "should return two rows when creating a variant" do
      v = FactoryGirl.create(:variant_with_stock_items) # stock is 10 items
            
      row1 = [v.name, "ready_to_wear", v.product.sku, v.product.sku, "", nil, nil, nil, nil, nil, nil, nil, "12.0", nil, nil, 0, 0, 0]
      row2 = [v.name, "ready_to_wear", v.product.sku, v.sku, "", nil, "12.0", nil, nil, nil, nil, nil, "12.0", nil, nil, 10, 0, 10]
      data = []
      report.retrieve_data do |d| 
        data << d
      end
      data.should =~ [row1, row2]
    end

    xit "should handle waiting for shipment quantities with one variant" do
      o = FactoryGirl.create(:order_ready_to_ship, line_items_count: 1) # ordered quantity is 1
      row1 = [o.line_items.first.variant.name, "ready_to_wear", o.line_items.first.variant.product.sku, o.line_items.first.variant.product.sku, "", nil, nil, nil, nil, nil, nil, nil, "12.0", nil, nil, 0, 0, 0]
      row2 = [o.line_items.first.variant.name, "ready_to_wear", o.line_items.first.variant.product.sku, o.line_items.first.variant.sku, "", nil, "12.0", nil, nil, nil, nil, nil, "12.0", nil, nil, 0, 1, 1]
      data = []
      report.retrieve_data do |d| 
        data << d
      end
      data.should =~ [row1, row2]
    end

  end
end


