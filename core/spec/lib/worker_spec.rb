require "spec_helper"
  describe Worker do
    let(:order)     { create(:order_with_line_items) }
    let(:kit)       { build(:product_type_kit) }
    let(:mailer)    { double }
    let(:line_item) { build(:line_item) }

    before do
      allow(Spree::ShipmentMailer).to receive(:knitting_experience_email).and_return(mailer)
      order.line_items << line_item
      order.products.last.product_type = kit
    end

    describe ".enque" do
      let(:job) { Shipping::KnittingExperienceMailer.new(order) }
      it "sends knitting experience email" do
        Worker.enque(job, 30.days)
        sent_mail = Delayed::Worker.new.run(Delayed::Job.last)
        expect(sent_mail).to eq true
      end
    end
  end