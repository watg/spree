require 'spec_helper'

describe Spree::OrderPostCompleteService do
  subject { Spree::OrderPostCompleteService }


  describe "run" do

    let!(:order) { Spree::Order.new }

    it "creates a AnalyticsJob" do
      expect {
        subject.run!(order: order, tracking_cookie: '12123')
      }.to change{ Delayed::Job.count }.by(1)
    end

  end
end
