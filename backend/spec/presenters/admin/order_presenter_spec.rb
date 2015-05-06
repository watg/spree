require 'spec_helper'

describe ::Admin::OrderPresenter, type: :presenter do
  let(:order)  { build_stubbed(:order) }
  subject { described_class.new(order, {}) }

  context "prioritizing orders" do
    subject { described_class.new(order, view, {}) }

    before { allow(view).to receive(:current_currency).and_return "USD" }

    describe ".delivery_type_class" do
      context "the order is express"  do
        it "returns express_delivery" do
          allow(order).to receive(:express?).and_return(true)
          expect(subject.delivery_type_class).to eq "express-delivery"
        end
      end
      context "the order is normal"  do
        it "returns normal_delivery" do
          allow_any_instance_of(Spree::Order).to receive(:express?).and_return(false)
          expect(subject.delivery_type_class).to eq "normal-delivery"
        end
      end
    end

    describe ".delivery_type" do
      context "the order is express"  do
        it "returns express" do
          allow(order).to receive(:express?).and_return(true)
          expect(subject.delivery_type).to eq "express"
        end
      end
      context "the order is normal"  do
        it "returns normal" do
          allow(order).to receive(:express?).and_return(false)
          expect(subject.delivery_type).to eq "normal"
        end
      end
    end
  end
  context "adjustments" do
    let(:adjustment) { build_stubbed(:adjustment, eligible: true, adjustable_type: adjustable_type) }

    before do
      allow(order).to receive(:all_adjustments).and_return([adjustment])
    end

    describe "#order_adjustments" do
      let(:adjustable_type) { "Spree::Order" }

      it "returns order adjustments" do
        expect(subject.order_adjustments).to eq [adjustment]
      end

      context "incorrect adjustable_type" do
        let(:adjustable_type) { "" }

        it "does not return order adjustments" do
          expect(subject.order_adjustments).to eq []
        end
      end
    end

    describe "#line_item_adjustments" do
      let(:adjustable_type) { "Spree::LineItem" }

      it "returns line_item adjustments" do
        expect(subject.line_item_adjustments).to eq [adjustment]
      end

      context "incorrect adjustable_type" do
        let(:adjustable_type) { "" }

        it "does not return order adjustments" do
          expect(subject.order_adjustments).to eq []
        end
      end
    end

    describe "#selected_shipping_rate_adjustments" do
      let(:adjustment) { build_stubbed(:adjustment, eligible: true) }
      let!(:shipping_rate) { build_stubbed(:selected_shipping_rate) }
      before { adjustment.adjustable = shipping_rate }

      it "returns selected shipping rate adjustments" do
        expect(subject.selected_shipping_rate_adjustments).to eq [adjustment]
      end

      context "unselected shipping rate" do
        let!(:shipping_rate) { build_stubbed(:shipping_rate, selected: false) }

        it "does not return selected shipping rate adjustments" do
          expect(subject.selected_shipping_rate_adjustments).to eq []
        end
      end
    end
  end
end

