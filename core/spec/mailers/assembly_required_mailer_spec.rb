require "spec_helper"

module Spree
  describe AssemblyRequiredMailer do
    subject          { described_class.new(order) }
    let(:order)      { create(:order_with_line_items, number: "99999") }
    let(:product)    { create(:product, assemble: true, name: "Hat66") }
    let(:line_items) { [] }
    let(:number)     { 5 }
    let(:mailer)     { double(deliver: nil) }
    let(:params)     { [/#{message}/, anything, anything] }

    before do
      Delayed::Worker.delay_jobs = false
      order.line_items.first.product = product
    end

    after { Delayed::Worker.delay_jobs = true }

    describe "#send" do
      context "order details" do
        let(:message) { %[<a href='http://www.example.com/admin/orders/99999/edit'>#99999</a>] }
        it "sends order details" do
          expect(NotificationMailer).to receive(:send_notification).with(*params).and_return(mailer)
          subject.send
        end
      end

      context "product details" do
        let(:message) { %[<b>Hat66</b>] }
        it "sends product details" do
          expect(NotificationMailer).to receive(:send_notification).with(*params).and_return(mailer)
          subject.send
        end
      end
    end
  end
end
