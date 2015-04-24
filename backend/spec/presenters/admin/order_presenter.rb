require "spec_helper"

describe Admin::OrderPresenter do
  let(:order) { build_stubbed(:order) }
  subject { described_class.new(order, view, {}) }

  before { allow(view).to receive(:current_currency).and_return "USD" }

  describe ".delivery_type_class" do
    context "the order is express"  do
      it "returns active" do
        allow_any_instance_of(Spree::Order).to receive(:express?).and_return(true)
        expect(subject.delivery_type_class).to eq "active"
      end
    end
    context "the order is normal"  do
      it "returns inactive" do
        allow_any_instance_of(Spree::Order).to receive(:express?).and_return(false)
        expect(subject.delivery_type_class).to eq "inactive"
      end
    end
  end

  describe ".delivery_type" do
    context "the order is express"  do
      it "returns express" do
        allow_any_instance_of(Spree::Order).to receive(:express?).and_return(true)
        expect(subject.delivery_type).to eq "express"
      end
    end
    context "the order is normal"  do
      it "returns normal" do
        allow_any_instance_of(Spree::Order).to receive(:express?).and_return(false)
        expect(subject.delivery_type).to eq "normal"
      end
    end
  end
end
