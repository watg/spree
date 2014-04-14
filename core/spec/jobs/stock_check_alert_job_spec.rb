require 'spec_helper'

describe Spree::StockCheckAlertJob do
  let(:variant) {create(:variant_with_stock_items)}
  let(:stock_item) { variant.stock_items.first }
  subject  { Spree::StockCheckAlertJob.new }

  before { Timecop.freeze }
  after { Timecop.return }

  describe "#perform" do
    context "plenty of stock" do

      it "sends no notificition" do
        expect(Spree::NotificationMailer).not_to receive(:send_notification)
        subject.perform
      end
    end

    # track inventory
    context "old out of stock item" do
      before do
        stock_item.update_columns(updated_at: 2.days.ago, backorderable: false, count_on_hand: 0)
      end

      it "sends no notificition" do
        expect(Spree::NotificationMailer).not_to receive(:send_notification)
        subject.perform
      end
    end


    context "recent out of stock item" do
      before do
        variant.product.name = 'Foo'
        variant.product.permalink = 'foo'
        variant.product.save
        stock_item.update_columns(updated_at: 1.days.ago, backorderable: false, count_on_hand: 0)
      end

      it "sends notificition" do
        message = ["product", "===========", "", "\t Foo,  , http://www.example.com//shop/admin/products/foo/stock","",""].join("\n")
        expect(Spree::NotificationMailer).to receive(:send_notification).with(message, "david@woolandthegang.com", "Items out of stock")
        subject.perform
      end
    end

    context "recent out of stock item" do
      before do
        stock_item.update_columns(updated_at: 1.days.ago, backorderable: true, count_on_hand: 0)
      end

      it "sends no notificition" do
        expect(Spree::NotificationMailer).not_to receive(:send_notification)
        subject.perform
      end

    end

  end

end
