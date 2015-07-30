require "spec_helper"

describe Spree::Parcel do
  let(:order)   { create(:order) }
  let(:box)     { create(:product, product_type: create(:product_type_packaging)) }
  subject do
    described_class.new(order_id: order.id,
                        box_id: box.id,
                        weight: 20.0,
                        height: 10.0,
                        width: 15.0,
                        depth: 4.0)
  end

  context "Class Methods" do
    subject      { described_class }
    let!(:boxes) { [create(:box)] }

    describe "#find_boxes" do
      subject { super().find_boxes }
      it { is_expected.to match_array(boxes) }
    end
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
