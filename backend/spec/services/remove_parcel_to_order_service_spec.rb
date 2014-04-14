require 'spec_helper'

describe Spree::RemoveParcelToOrderService do
  let(:stock_location) { Spree::StockLocation.create!(name: 'warehouse') }
  context "#run" do
    let(:subject)   { Spree::RemoveParcelToOrderService }
    let(:box_group) { FactoryGirl.create(:product_group, name: 'box')}
    let!(:small_box) { FactoryGirl.create(:product, product_type: :product, individual_sale: false, product_group_id: box_group.id) }
    let(:order)     { FactoryGirl.create(:order) }

    it "should invoke success callback when all is good" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: order.id)
      expect(outcome).to be_success
    end

    it "should remove parcel to order" do
      Spree::Parcel.should_receive(:destroy).with(order.parcels.map(&:id))
      subject.run(box_id: small_box.id, quantity: 1, order_id: order.id)
    end

    it "should invoke failure callback on wrong quantity" do
      outcome = subject.run(box_id: small_box.id, quantity: -1, order_id: order.id)
      expect(outcome).not_to be_success
    end

    it "should invoke failure callback on wrong box_id" do
      outcome = subject.run(box_id: 99999999, quantity: 1, order_id: order.id)
      expect(outcome).not_to be_success
    end

    it "should invoke failure callback on wrong box_id" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: 99999999)
      expect(outcome).not_to be_success
    end

    context "stock level control" do
      before do
        stock_item = small_box.master.stock_items[0]
        stock_item.adjust_count_on_hand(10)
      end

      it "should decrement stock of selected box by correct quantity" do
        # Spree::StockLocation.delete_all
        # Spree::StockLocation.create!(name: 'warehouse')
        subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)
        puts small_box.stock_items.inspect
        expect(small_box.stock_items[0].count_on_hand).to eq(14)
      end
    end

    context "allocated order" do
      let(:order) { FactoryGirl.create(:allocated_order) }
      it "cannot remove parcels" do
        allow(Spree::Order).to receive(:find).and_return(order)
        outcome = subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)

        expect(outcome.success?).to be_false
      end
    end


  end

end
