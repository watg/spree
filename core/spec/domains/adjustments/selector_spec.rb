require "spec_helper"

describe Adjustments::Selector do
  let!(:adjustment) { mock_model(Spree::Adjustment) }
  subject { described_class.new([adjustment]) }

  # so you give it an array of adjustments
  # and if you call line item - it reutns an array of adjustemnts that has line items in it
  describe "#line_item" do
    context "when an array contains an adjustment with line item as adjustable type" do
      it "creates a new adjustor with said adjustment" do
        allow(adjustment).to receive(:adjustable_type).and_return("Spree::LineItem")

        expect(subject.line_item).to be_kind_of(described_class)
        expect(subject.line_item.adjustments).to eq([adjustment])
      end
    end

    context "when an array has no line item as adjustable type" do
      it "creates a new adjustor with an empty array on adjustments" do
        expect(subject.line_item).to be_kind_of(described_class)
        expect(subject.line_item.adjustments).to eq([])
      end
    end
  end

  describe "#shipping_rate" do
    context "when an array contains an adjustment with shipping rate as adjustable type" do
      it "creates a new adjustor with said adjustment" do
        allow(adjustment).to receive(:adjustable_type).and_return("Spree::ShippingRate")

        expect(subject.shipping_rate).to be_kind_of(described_class)
        expect(subject.shipping_rate.adjustments).to eq([adjustment])
      end
    end

    context "when an array has no shipping rate as adjustable type" do
      it "creates a new adjustor with an empty array on adjustments" do
        expect(subject.shipping_rate).to be_kind_of(described_class)
        expect(subject.shipping_rate.adjustments).to eq([])
      end
    end
  end

  describe "#order" do
    context "when an array contains an adjustment with shipping rate as adjustable type" do
      it "creates a new adjustor with said adjustment" do
        allow(adjustment).to receive(:adjustable_type).and_return("Spree::Order")

        expect(subject.order).to be_kind_of(described_class)
        expect(subject.order.adjustments).to eq([adjustment])
      end
    end

    context "when an array has no shipping rate as adjustable type" do
      it "creates a new adjustor with an empty array on adjustments" do
        expect(subject.order).to be_kind_of(described_class)
        expect(subject.order.adjustments).to eq([])
      end
    end
  end

  describe "#eligible" do
    context "when adjustments array contains eligible adjustments" do
      it "returns a selector with eligible adjustments" do
        allow(adjustment).to receive(:eligible).and_return(true)

        expect(subject.eligible).to be_kind_of(described_class)
        expect(subject.eligible.adjustments).to eq([adjustment])
      end
    end

    context "when adjustments array does not contain eligible adjustments" do
      it "returns a selctor with no adjustments" do
        expect(subject.eligible).to be_kind_of(described_class)
        expect(subject.eligible.adjustments).to eq([])
      end
    end
  end

  describe "#promotion" do
    context "when adjustments array contains adjustment with promotion action" do
      it "returns a selector with said adjustments" do
        allow(adjustment).to receive(:source_type).and_return("Spree::PromotionAction")

        expect(subject.promotion).to be_kind_of(described_class)
        expect(subject.promotion.adjustments).to eq([adjustment])
      end
    end

    context "when adjustments array does not contain adjustment with promotion action" do
      it "returns a selctor with no adjustments" do
        expect(subject.promotion).to be_kind_of(described_class)
        expect(subject.promotion.adjustments).to eq([])
      end
    end
  end

  describe "#tax" do
    context "when adjustments array contains adjustment with tax action" do
      it "returns a selector with said adjustments" do
        allow(adjustment).to receive(:source_type).and_return("Spree::TaxRate")

        expect(subject.tax).to be_kind_of(described_class)
        expect(subject.tax.adjustments).to eq([adjustment])
      end
    end

    context "when adjustments array does not contain adjustment with tax action" do
      it "returns a selctor with no adjustments" do
        expect(subject.tax).to be_kind_of(described_class)
        expect(subject.tax.adjustments).to eq([])
      end
    end
  end

  describe "#without_shipping_rate" do
    context "when adjustments array contains multiple adjustments and has shipping_rate action" do
      let!(:adjustment2) { mock_model(Spree::Adjustment) }
      subject { described_class.new([adjustment, adjustment2]) }

      it "returns a selector without shipping_rate adjustment" do
        allow(adjustment).to receive(:source_type).and_return("Spree::TaxRate")
        allow(adjustment2).to receive(:adjustable_type).and_return("Spree::ShippingRate")

        expect(subject.without_shipping_rate).to be_kind_of(described_class)
        expect(subject.without_shipping_rate.adjustments).to eq([adjustment])
      end
    end

    context "when adjustments array does not contain an adjustment with shipping_rate action" do
      it "returns the same adjustment array" do
        expect(subject.without_shipping_rate).to be_kind_of(described_class)
        expect(subject.without_shipping_rate.adjustments).to eq([adjustment])
      end
    end
  end

  describe "#without_tax" do
    context "when adjustments array contains multiple adjustments and has tax adjustable type" do
      let!(:adjustment2) { mock_model(Spree::Adjustment) }
      subject { described_class.new([adjustment, adjustment2]) }

      it "returns a selector without shipping_rate adjustment" do
        allow(adjustment).to receive(:source_type).and_return("Spree::TaxRate")
        allow(adjustment2).to receive(:adjustable_type).and_return("Spree::ShippingRate")

        expect(subject.without_shipping_rate).to be_kind_of(described_class)
        expect(subject.without_tax.adjustments).to eq([adjustment2])
      end
    end

    context "when adjustments array does not contain an adjustment with tax adjustable type" do
      it "returns the same adjustment array" do
        expect(subject.without_shipping_rate).to be_kind_of(described_class)
        expect(subject.without_shipping_rate.adjustments).to eq([adjustment])
      end
    end
  end
end
