require 'spec_helper'

module Shipping
  describe KitAndPatternEmailSurveyJob do
    subject         { described_class.new(order) }
    let(:order)     { create(:order_with_line_items) }
    let(:line_item) { create(:line_item) }
    let(:mailer)    { double }
    let(:normal)    { create(:product_type) }
    let(:kit)       { create(:product_type_kit) }
    let(:pattern)   { create(:marketing_type, :pattern) }

    describe '#perform' do
      before do
        stub_const("Shipping::KitAndPatternEmailSurveyJob::DELAY", "1 month")
        allow(Spree::ShipmentMailer).to receive(:kit_and_pattern_survey_email).and_return(mailer)
        order.line_items << line_item
      end

      context 'order contains kit' do
        before { order.products.last.product_type = kit }

        it 'sends email to customers in 1 month' do
          expect(mailer).to receive(:delay).with({:run_at=> "1 month"}).and_return(mailer)
          expect(mailer).to receive(:deliver)
          subject.perform
        end
      end

      context 'order contains pattern' do
        before { order.products.last.marketing_type = pattern }

        it 'sends email to customers in 1 month' do
          expect(mailer).to receive(:delay).with({:run_at=> "1 month"}).and_return(mailer)
          expect(mailer).to receive(:deliver)
          subject.perform
        end
      end

      context 'order contains multiple kits' do
        before { order.products.map { |p| p.product_type = kit } }

        it 'send email once' do
          expect(mailer).to receive(:delay).with({:run_at=> "1 month"}).and_return(mailer)
          expect(mailer).to receive(:deliver).once
          subject.perform
        end
      end

      context 'order contains kit and pattern' do
        before do
          order.products.first.product_type = kit
          order.products.last.marketing_type = pattern
        end

        it 'send email once' do
          expect(mailer).to receive(:delay).with({:run_at=> "1 month"}).and_return(mailer)
          expect(mailer).to receive(:deliver).once
          subject.perform
        end
      end

      context 'order does not contain pattern or kit' do
        let(:embellishment) { create(:marketing_type, :embellishment) }

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
