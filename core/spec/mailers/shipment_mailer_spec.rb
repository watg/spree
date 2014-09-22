require 'spec_helper'
require 'email_spec'

describe Spree::OrderMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers


  context "survey_email" do
    let(:order) { create(:order) }

    before do
      Delayed::Worker.delay_jobs = false
      Spree::ShipmentMailer.survey_email(order).deliver
      @message = ActionMailer::Base.deliveries.last
      @header = JSON.parse(@message.header['X-MC-MergeVars'].value)
    end

    after do
      Delayed::Worker.delay_jobs = true
    end

    it 'sends an email' do
      expect(@message.subject).to eq "Order Number #{order.number}, How did we do?"
      expect(@message.header['X-MC-Template'].value).to eq "en_survey_email"
      expect(@header["order_number"]).to eq order.number
      expect(@header["email"]).to eq order.email
    end
  end
end
