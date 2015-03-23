require "spec_helper"

describe Spree::GlobalFreeShippingPresenter do
  let(:device) { :desktop }
  let(:template) { { current_currency: "USD", current_country_code: "US" } }

  subject { described_class.new(view) }

  context "with global promotion configured correctly" do
    before do
      allow(view).to receive(:current_country_code).and_return("US")
      allow(view).to receive(:current_currency).and_return("USD")
      allow(subject).to receive(:promotion).and_return(promotable)
    end

    context "with free shipping available" do
      let(:promotable) { double(Spree::Promotion, eligible?: true, amount: 100) }

      # stub eligible promotion to return a hash - 100 and
      it "returns true for free shipping" do
        expect(subject.eligible?).to eq true
      end

      it "returns free shipping amount in correct format" do
        expect(subject.amount).to eq "$100.00"
      end
    end

    context "with free shipping unavailable" do
      let(:promotable) { double(Spree::Promotion, eligible?: false, amount: 0) }

      it "returns false for free shipping" do
        expect(subject.eligible?).to eq false
      end

      it "free shipping amount is set to 0" do
        expect(subject.amount).to eq "$0.00"
      end
    end
  end

  context "without global promotion configured" do
    it "returns returns false for free shipping" do
      allow(view).to receive(:current_country_code).and_return("US")
      allow(view).to receive(:current_currency).and_return("USD")
      expect(subject.eligible?).to eq false
      expect(subject.amount).to eq "$0.00"
    end
  end
end
