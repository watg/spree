require 'spec_helper'

describe Spree::AddParcelToOrderService do
  let!(:stock_location) { Spree::StockLocation.create!(name: 'warehouse') }
  context "#run" do
    let(:subject)   { Spree::AddParcelToOrderService }
    let(:box_group) { FactoryGirl.create(:product_group, name: 'box')}
    let(:small_box) { FactoryGirl.create(:product, product_type: create(:product_type_packaging), individual_sale: false, product_group_id: box_group.id, weight: 5.0, depth: 30.0, width: 34.0, height: 20.0) }
    let(:order)     { FactoryGirl.create(:order) }

    it "should invoke success callback when all is good" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: order.id)
      expect(outcome.valid?).to be_true
    end

    it "should add parcel to order" do
      expected = {
        weight: small_box.weight,
        height: small_box.height,
        width:  small_box.width,
        depth:  small_box.depth,
        box_id: small_box.id,
        order_id:   order.id
      }

      Spree::Parcel.should_receive(:create!).with(expected)
      subject.run(box_id: small_box.id , quantity:   1, order_id:   order.id)
    end

    it "should invoke failure callback on wrong quantity" do
      outcome = subject.run(box_id: small_box.id, quantity: -1, order_id: order.id)
      expect(outcome.valid?).to be_false
    end

    it "should invoke failure callback on wrong box_id" do
      outcome = subject.run(box_id: 99999999, quantity: 1, order_id: order.id)
      expect(outcome.valid?).to be_false
    end

    it "should invoke failure callback on wrong box_id" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: 99999999)
      expect(outcome.valid?).to be_false
    end

    context "stock level control" do
      before do
        stock_item = small_box.master.stock_items[0]
        stock_item.adjust_count_on_hand(10)
      end

      it "should decrement stock of selected box by correct quantity" do
        subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)
        expect(small_box.stock_items[0].count_on_hand).to eq(6)
      end
    end

    context "allocated order" do
      before { order.metapack_allocated = true }
      it "cannot have more parcels" do
        allow(Spree::Order).to receive(:find).and_return(order)
        outcome = subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)

        expect(outcome.valid?).to be_false
      end
    end
  end


end
