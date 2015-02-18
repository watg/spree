require 'spec_helper'

describe Spree::Order do
  let(:order) { FactoryGirl.create(:completed_order_with_pending_payment) }
  let(:product_type_gift_card) { create(:product_type_gift_card) }

  context "METAPACK" do
    let(:order_with_weight)  { create(:order_ready_to_be_consigned_and_allocated) }

    it "should boxes weight should be added to the order" do
      variants_weight = order_with_weight.line_items.map{ |li| li.variant.weight * li.quantity }.sum.to_f
      expect(order_with_weight.weight.round(2)).to eq((variants_weight.round(2) + 0.6).round(2))
    end
    it "should have max_dimension" do
      expect(order_with_weight.max_dimension).to eq(40.0)
    end
  end

  describe "#not_cancelled" do

    let!(:order) { create(:order, state: :complete, completed_at: Time.now) }
    let!(:cancelled_order) { create(:order, state: :canceled, completed_at: Time.now) }

    it "returns only not cancelled orders" do
      expect(described_class.not_cancelled).to eq [ order ]
    end

  end

  describe "#to_be_packed_and_shipped" do
    let!(:order_with_one_digital_line_item) { create(:order_with_line_items, line_items_count: 2,
                                        payment_state: 'paid', shipment_state: 'ready', state: 'complete') }
    let!(:order_with_digital_line_items_only) { create(:order_with_line_items, line_items_count: 1,
                                        payment_state: 'paid', shipment_state: 'ready', state: 'complete') }

    before do
      p1 = order_with_one_digital_line_item.line_items.first.product
      p1.product_type.update_column(:is_digital, true)

      p2 = order_with_digital_line_items_only.line_items.first.product
      p2.product_type.update_column(:is_digital, true)
    end

    it "disregards orders with digital products only" do
       result = Spree::Order.to_be_packed_and_shipped
      expect(result.size).to eq 1
      expect(result.first).to eq order_with_one_digital_line_item
    end

    it "includes resumed orders" do
      resumed_order = create(:order_ready_to_be_consigned_and_allocated, state: 'resumed')
      result = Spree::Order.to_be_packed_and_shipped
      expect(result).to include(resumed_order)
    end
  end

  describe "#unprinted_invoices and #unprinted_image_stickers" do
    let!(:unprinted_invoices) { create(:order_with_line_items, line_items_count: 1,
                                        payment_state: 'paid', shipment_state: 'ready', state: 'complete') }
    let!(:printed_invoice) { create(:order_with_line_items, line_items_count: 1,
                                    batch_invoice_print_date: Date.today, payment_state: 'paid', shipment_state: 'ready', state: 'complete') }
    let!(:unfinished_order) { create(:order_with_line_items, line_items_count: 1,
                                    payment_state: 'balance_due', shipment_state: 'ready', state: 'complete') }

    it "returns orders in shipment_state = ready with no invoice print date" do
      expect(Spree::Order.unprinted_invoices).to eq ([unprinted_invoices])
      expect(Spree::Order.unprinted_image_stickers).to eq ([printed_invoice])
    end
  end

  describe ".last_batch_id" do
    it "returns the highest batch ID ever allocated" do
      FactoryGirl.create(:order,
        :batch_invoice_print_date => Date.yesterday,
        :batch_print_id => "17")
      FactoryGirl.create(:order,
        :batch_invoice_print_date => Date.yesterday,
        :batch_print_id => "9")
      expect(Spree::Order.last_batch_id).to eq(17)
    end

    it "returns 0 if no orders match" do
      expect(Spree::Order.last_batch_id).to eq(0)
    end

    it "doesn't return 0 just because a nil exists" do
      FactoryGirl.create(:order,
        :batch_invoice_print_date => Date.yesterday,
        :batch_print_id => "17")
      FactoryGirl.create(:order,
        :batch_invoice_print_date => Date.yesterday,
        :batch_print_id => nil)
      expect(Spree::Order.last_batch_id).to eq(17)
    end
  end

  describe "#line_items_without_gift_cards" do
    subject { create(:order_with_line_items, line_items_count: 1) }
    let!(:li_gc) { create(:line_item, quantity: 1, variant: create(:product, product_type: product_type_gift_card).master, order: subject) }

    it "only returns line items without gift card in them" do
      expect(subject.line_items_without_gift_cards).to match_array(subject.line_items)
    end
  end

  describe "#physical_line_items" do
    subject { create(:order_with_line_items, line_items_count: 1) }
    let!(:digital_line_item) { create(:line_item, variant: create(:product, product_type: create(:product_type, is_digital: true)).master, order: subject) }

    it "only returns line items without digital items in them" do
      expect(subject.physical_line_items).to match_array(subject.line_items)
    end
  end

  describe "#has_gift_card?" do
    subject { create(:order_with_line_items) }

    describe '#has_gift_card?' do
      subject { super().has_gift_card? }
      it { is_expected.to be_falsey }
    end

    it "returns ture when order has at least one gift card" do
      gift_line_item = create(:line_item, quantity: 1, variant: create(:product, product_type: product_type_gift_card).master, order: subject)
      expect(subject.reload.has_gift_card?).to be true
    end
  end

  describe "#mark_as_internal_and_send_email_if_assembled" do
    let(:supplier) { create(:supplier) }
    subject { create(:order_with_line_items, line_items_count: 1) }

    before do
      Delayed::Worker.delay_jobs = false
      line_item = subject.line_items.first
      create(:part, line_item: line_item, variant_id: 0, assembled: true)
      Spree::StockItem.all.each { |si| si.update_attributes(supplier: supplier) }
    end

    after { Delayed::Worker.delay_jobs = true }

    it "marks the order as internal and sends an email" do
      expect(Spree::NotificationMailer).to receive(:send_notification).with(anything, ['test@woolandthegang.com'], 'Customisation Order #' + subject.number.to_s).and_return double.as_null_object

      expect {
        subject.finalize!
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(subject.reload.internal).to be true
    end

  end

  describe "prioritised" do
    let!(:older) { create(:order, completed_at: 5.minutes.ago, important: false)}
    let!(:newer) { create(:order, completed_at: 1.minute.ago)}
    let!(:important2) { create(:order, completed_at: 1.week.ago, important: true) }
    let!(:important1) { create(:order, completed_at: 10.minutes.ago, important: true) }

    it "sorts by 'important' and then by competion date" do
      expect(Spree::Order.prioritised.to_a).to eq([important1, important2, newer, older])
    end
  end

  describe "reactivate_gift_cards!" do

    let!(:gift_card_1) { create(:gift_card, beneficiary_order: order, state: 'redeemed')}
    let!(:gift_card_2) { create(:gift_card, beneficiary_order: order, state: 'cancelled')}

    it "reactivate all redemmed gift cards redeemed against an order" do
      order.reactivate_gift_cards!
      expect(gift_card_1.reload.state).to eq('not_redeemed')
      expect(gift_card_1.beneficiary_order).to be_nil
      expect(gift_card_2.reload.state).to eq('cancelled')
      expect(gift_card_2.beneficiary_order).to eq order
    end
    
  end

end
