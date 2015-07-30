require "spec_helper"

describe Spree::AddParcelToOrderService do
  context "#run" do
    let(:subject)   { described_class }
    let(:small_box) { FactoryGirl.create(:product, product_type: create(:product_type_packaging), individual_sale: false, weight: 5.0, depth: 30.0, width: 34.0, height: 20.0) }
    let(:order)     { FactoryGirl.create(:order) }

    it "invokes success callback when all is good" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: order.id)
      expect(outcome.valid?).to be true
    end

    it "adds parcel to order" do
      expected = {
        weight: small_box.weight,
        height: small_box.height,
        width:  small_box.width,
        depth:  small_box.depth,
        box_id: small_box.id,
        order_id:   order.id
      }

      expect(Spree::Parcel).to receive(:create!).with(expected)
      subject.run(box_id: small_box.id, quantity:   1, order_id:   order.id)
    end

    it "invokes failure callback on wrong quantity" do
      outcome = subject.run(box_id: small_box.id, quantity: -1, order_id: order.id)
      expect(outcome.valid?).to be false
    end

    it "invokes failure callback on wrong box_id" do
      outcome = subject.run(box_id: 99_999_999, quantity: 1, order_id: order.id)
      expect(outcome.valid?).to be false
    end

    it "invokes failure callback on wrong box_id" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: 99_999_999)
      expect(outcome.valid?).to be false
    end

    context "stock level control" do
      before do
        stock_item = small_box.master.stock_items[0]
        stock_item.adjust_count_on_hand(10)
      end

      it "decrements stock of selected box by correct quantity" do
        subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)
        expect(small_box.stock_items[0].count_on_hand).to eq(6)
      end
    end

    context "allocated order" do
      before { order.metapack_allocated = true }
      it "cannot have more parcels" do
        allow(Spree::Order).to receive(:find).and_return(order)
        outcome = subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)

        expect(outcome.valid?).to be false
      end
    end
  end
end
