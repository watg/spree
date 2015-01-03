require 'spec_helper'

describe Spree::ProductType do
  subject { product_type }

  let(:product_type) { create(:product_type) }

  describe "requires_supplier" do

    it "is true" do
      expect(subject.requires_supplier?).to be true
    end

    context "is_operational" do
      before { allow_any_instance_of(Spree::ProductType).to receive_messages is_operational?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be false
      end

    end

    context "is_digital" do
      before { allow_any_instance_of(Spree::ProductType).to receive_messages is_digital?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be false
      end

    end

    context "has an assembly definition" do
      before { allow_any_instance_of(Spree::ProductType).to receive_messages is_assembly?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be false
      end

    end

  end
end
