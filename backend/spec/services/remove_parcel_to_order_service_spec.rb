require "spec_helper"

describe Spree::RemoveParcelToOrderService do
  let(:stock_location) { Spree::StockLocation.create!(name: "warehouse") }
  context "#run" do
    let(:subject)   { described_class }
    let(:small_box) { FactoryGirl.create(:product, individual_sale: false) }
    let!(:order)     { FactoryGirl.create(:order) }

    it "invokes success callback when all is good" do
      outcome = subject.run(box_id: small_box.id, quantity: 1, order_id: order.id)
      expect(outcome.valid?).to be true
    end

    it "removes parcel to order" do
      expect(Spree::Parcel).to receive(:destroy).with(order.parcels.map(&:id))
      subject.run(box_id: small_box.id, quantity: 1, order_id: order.id)
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
        # Spree::StockLocation.delete_all
        stock_item = small_box.master.stock_items[0]
        stock_item.adjust_count_on_hand(10)
      end

      it "decrements stock of selected box by correct quantity" do
        subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)
        expect(small_box.stock_items.sum(:count_on_hand)).to eq(14)
      end
    end

    context "allocated order" do
      before { order.metapack_allocated = true }
      it "cannot remove parcels" do
        allow(Spree::Order).to receive(:find).and_return(order)
        outcome = subject.run(box_id: small_box.id, quantity: 4, order_id: order.id)

        expect(outcome.valid?).to be false
      end
    end
  end
end
