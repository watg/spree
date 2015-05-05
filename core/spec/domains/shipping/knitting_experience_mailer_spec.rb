require 'spec_helper'

module Shipping
  describe KnittingExperienceMailer do
    subject         { described_class.new(order) }
    let(:order)     { build(:order_with_line_items) }
    let(:line_item) { build(:line_item) }
    let(:mailer)    { double }
    let(:kit)       { build(:product_type_kit) }
    let(:pattern)   { build(:product_type, :pattern) }

    describe '#perform' do
      before do
        order.line_items << line_item
        allow(Spree::ShipmentMailer).to receive(:knitting_experience_email).with(order).and_return(mailer)
      end

      context 'order contains kit' do
        before { order.products.last.product_type = kit }

        it 'sends email to customers in 1 month' do
          expect(mailer).to receive(:deliver)
          subject.perform
        end
      end

      context 'order contains pattern' do
        before { order.products.last.product_type = pattern }

        it 'sends email to customers in 1 month' do
          expect(mailer).to receive(:deliver)
          subject.perform
        end
      end

      context 'order contains multiple kits' do
        before { order.products.map { |p| p.product_type = kit } }

        it 'send email once' do
          expect(mailer).to receive(:deliver).once
          subject.perform
        end
      end

      context 'order contains kit and pattern' do
        before do
          order.products.first.product_type = kit
          order.products.last.product_type = pattern
        end

        it 'send email once' do
          expect(mailer).to receive(:deliver).once
          subject.perform
        end
      end

      context 'order does not contain pattern or kit' do
        let(:embellishment) { create(:marketing_type, :embellishment) }
        let(:normal)        { build(:product_type) }

        before do
          order.products.first.marketing_type = embellishment
          order.products.first.product_type   = normal
        end

        it 'does not sends email to customer' do
          expect(mailer).to_not receive(:deliver)
          subject.perform
        end
      end
    end
  end
end
