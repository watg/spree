require 'spec_helper'

describe Spree::StockCheckAlertJob do
  let(:variant) {create(:variant_with_stock_items)}
  let(:stock_item) { variant.stock_items.first }
  let(:marketing_type) { create(:marketing_type) }
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
        variant.product.marketing_type = marketing_type
        variant.product.name = 'name'
        variant.product.slug = 'slug'
        variant.sku =  'sku'
        variant.save
        variant.product.save
        stock_item.update_columns(updated_at: 1.days.ago, backorderable: false, count_on_hand: 0)
      end

      it "sends notificition" do
        message = [variant.product.marketing_type.name, "===========", "", "\t name, sku, #{Spree::Core::Engine.routes.url_helpers.stock_admin_product_url(variant.product)}","",""].join("\n")

        mock_object = double("mock_object")
        expect(mock_object).to receive(:deliver)

        expect(Spree::NotificationMailer).to receive(:send_notification).with(message, ['test@woolandthegang.com'], "Items out of stock").and_return(mock_object)
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

    context "when there is stock in feeder stores" do
      let(:active_location) { create(:stock_location, active: true) }
      let(:feeder) { create(:stock_location, active: false, feed_into: active_location) }
      let!(:alternative_stock) { create(:stock_item, stock_location: feeder, variant: variant)}

      before do
        alternative_stock.set_count_on_hand(1)
        stock_item.update_columns(updated_at: 1.days.ago, backorderable: false, count_on_hand: 0)
      end

      it "does not send a notification" do
        expect(Spree::NotificationMailer).not_to receive(:send_notification)
        subject.perform
      end
    end

    context "when there is stock in inactive, non-feeder stores" do
      let(:active_location) { create(:stock_location, active: true) }
      let(:inactive_location) { create(:stock_location, active: false) }
      let(:alternative_stock) { create(:stock_item, stock_location: inactive_location, count_on_hand: 1, variant: variant)}

      before do
        stock_item.update_columns(updated_at: 1.days.ago, backorderable: false, count_on_hand: 0)
        variant.product.update_column(:marketing_type_id, marketing_type.id)
      end

      it "sends a notification" do
        mock_object = double("mock_object")
        expect(mock_object).to receive(:deliver)

        expect(Spree::NotificationMailer).to receive(:send_notification).and_return(mock_object)
        subject.perform
      end
    end

  end

end
