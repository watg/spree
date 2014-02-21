require 'spec_helper'

describe Spree::DigitalOnlyOrderShipperJob do
  it "marks order with only digital items as shipped" do
    order = create(:order_with_line_items)
    order.line_items.each {|li| li.product_nature = 'digital'; li.save }

    job = Spree::DigitalOnlyOrderShipperJob.new(order)
    job.perform

    expect(order.shipment_state).to eq('shipped')
  end

  it "leaves order with physical items untouched" do
    line_item = create(:line_item, product_nature: 'physical')
    order = line_item.order
    job = Spree::DigitalOnlyOrderShipperJob.new(order)
    job.perform

    expect(order.shipment_state).to_not eq('shipped')
  end

  it "leaves order with mixed physical and digital items untouched" do
    line_item = create(:line_item, product_nature: 'physical')
    order = line_item.order
    create(:line_item, product_nature: 'digital', order: order)
        
    job = Spree::DigitalOnlyOrderShipperJob.new(order)
    job.perform

    expect(order.shipment_state).to_not eq('shipped')
  end

end
