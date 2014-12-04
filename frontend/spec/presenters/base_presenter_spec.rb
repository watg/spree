require 'spec_helper'

describe Spree::BasePresenter do

  let(:target) { mock_model(Spree::Target) }
  let(:suite) { Spree::Suite.new(target: target) }
  let(:tab) { Spree::StuieTab.new(tab_type: 'arbitrary') }
  let(:context) { { currency: 'USD', target: target, suite: suite, device: :desktop}}
  subject { described_class.new(target, suite, context) }

  describe "#is_desktop" do
    it 'returns desktop as device' do
      expect(subject.send(:is_mobile?)).to eq false
      expect(subject.send(:is_desktop?)).to eq true
    end
  end

  describe "#is_mobile" do
    let(:context) { { currency: 'USD', target: target, suite: suite, device: :mobile}}

    it 'returns mobile as device' do
      expect(subject.send(:is_mobile?)).to eq true
      expect(subject.send(:is_desktop?)).to eq false
    end
  end
end