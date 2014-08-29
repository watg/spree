require 'spec_helper'

describe Spree::ProductType do
  subject { product_type }

  let(:product_type) { create(:product_type) }

  describe "requires_supplier" do

    it "is true" do
      expect(subject.requires_supplier?).to be_true
    end

    context "is_operational" do
      before { Spree::ProductType.any_instance.stub is_operational?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be_false
      end

    end

    context "is_digital" do
      before { Spree::ProductType.any_instance.stub is_digital?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be_false
      end

    end

    context "has an assembly definition" do
      before { Spree::ProductType.any_instance.stub is_assembly?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be_false
      end

    end

  end
end
