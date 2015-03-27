require 'spec_helper'

describe ApplicationController, type: :controller do

  subject { described_class.new }

  describe "#device" do
    context "user agent recongised" do
      it "sets the correct devise" do
        request = double(:user_agent => 'iPhone' )
        allow(subject).to receive(:request).and_return(request)
        expect(subject.device).to eq :mobile
      end
    end

    context "no user_agent" do
      it "sets the correct device to desktop" do
        request = double(:user_agent => 'asdaklsdj' )
        allow(subject).to receive(:request).and_return(request)
        expect(subject.device).to eq :desktop
      end
    end
  end

  describe "#context" do
    it "returns an object with context accessor methods" do
      allow(subject).to receive(:device).and_return("my_device")
      allow(subject).to receive(:current_currency).and_return("USD")

      expect(subject.context[:device]).to eq "my_device"
      expect(subject.context[:currency]).to eq "USD"
    end
  end
end
