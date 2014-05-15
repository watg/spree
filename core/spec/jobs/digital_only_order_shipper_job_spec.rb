require 'spec_helper'

describe Spree::DigitalOnlyOrderShipperJob do

  let(:digital_product) { create(:product, is_digital: true)}
  let(:physical_product) { create(:product, is_digital: false)}
  let(:order) { create(:order_with_line_items) }


  it "marks order with only digital items as shipped" do
    order.line_items.each {|li| li.variant.product = digital_product; li.save }
    job = Spree::DigitalOnlyOrderShipperJob.new(order)
    job.perform
    expect(order.shipment_state).to eq('shipped')
  end

  it "leaves order with mixed physical and digital items untouched" do
    order.line_items.first {|li| li.variant.product = digital_product; li.save }
        
    job = Spree::DigitalOnlyOrderShipperJob.new(order)
    job.perform

    expect(order.shipment_state).to_not eq('shipped')
  end

end
