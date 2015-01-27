require 'spec_helper'

describe Spree::OrderPostPaymentNotifier do
  let(:order) { create(:order) }
  subject(:notifier) { Spree::OrderPostPaymentNotifier.new(order) }

  describe "#process" do
    describe "send gift card" do
      context "when the order has a gift card" do
        before do
          allow(order).to receive(:has_gift_card?).and_return(true)
        end

        context "when an email has already been sent" do
          it "does not create a gift card job" do
            Spree::NotificationEmail.create!(order: order, email_type: :gift_card)
            expect(Spree::GiftCardJobCreator).not_to receive(:new)
            notifier.process
          end
        end

        context "when no email has already been sent" do
          it "creates a gift card job" do
            creator = double(Spree::GiftCardJobCreator)
            expect(Spree::GiftCardJobCreator).to receive(:new).with(order).and_return(creator)
            expect(creator).to receive(:run)
            notifier.process
          end

          it "only sends one email" do
            creator = double(Spree::GiftCardJobCreator)
            expect(Spree::GiftCardJobCreator).to receive(:new).with(order).and_return(creator).once
            expect(creator).to receive(:run).once
            notifier.process
            notifier.process
          end
        end
      end

      context "when the order does not contain a gift card" do
        before do
          allow(order).to receive(:has_gift_card?).and_return(false)
        end

        it "does not create a gift card job" do
          expect(Spree::GiftCardJobCreator).not_to receive(:new)
          notifier.process
        end
      end
    end

    describe "send digital pattern" do
      context "when the order contains digital links" do
        before do
          allow(order).to receive(:some_digital?).and_return(true)
        end

        context "when an email has already been sent" do
          it "does not send a digital download email" do
            Spree::NotificationEmail.create!(order: order, email_type: :digital_download)
            expect(Spree::DigitalDownloadMailer).not_to receive(:delay)
            notifier.process
          end
        end

        context "when no email has already been sent" do
          it "sends a digital download email" do
            mailer = double(Spree::DigitalDownloadMailer)
            expect(Spree::DigitalDownloadMailer).to receive(:delay).and_return(mailer)
            expect(mailer).to receive(:send_links).with(order)
            notifier.process
          end

          it "only sends one email" do
            mailer = double(Spree::DigitalDownloadMailer)
            expect(Spree::DigitalDownloadMailer).to receive(:delay).and_return(mailer).once
            expect(mailer).to receive(:send_links).with(order).once
            notifier.process
            notifier.process
          end
        end
      end

      context "when the order does not contain digital links" do
        before do
          allow(order).to receive(:some_digital?).and_return(false)
        end

        it "does not send an email" do
          expect(Spree::DigitalDownloadMailer).not_to receive(:delay)
          notifier.process
        end
      end
    end
  end
end
