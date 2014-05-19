require 'spec_helper'

describe Spree::Parcel do
  let(:order)   { create(:order) }
  let(:box)     { create(:product, product_type: create(:product_type_packaging)) }
  subject { Spree::Parcel.new(order_id: order.id,
                              box_id: box.id,
                              weight: 20.0,
                              height: 10.0,
                              width: 15.0,
                              depth: 4.0) }
  
  context "Class Methods" do
    subject      { Spree::Parcel }
    let!(:boxes) { [create(:box)] }
#    its(:find_boxes) { should match_array(boxes) }
  end
 
  context "Validation" do
    [:box_id, :order_id, :weight, :height, :width, :depth].each do |field|
      it "should be present  #{field}" do
        subject.send("#{field}=", nil)
        expect(subject).to be_invalid 
      end
    end
  end
  

end
