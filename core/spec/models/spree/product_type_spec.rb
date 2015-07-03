require 'spec_helper'

describe Spree::ProductType do
  subject { create(:product_type) }

  describe '.default' do
    let!(:normal) { create(:product_type) }
    let!(:gift)   { create(:product_type_gift_card) }

    it { expect(described_class.default).to be_normal }
  end

  describe "#pattern?" do
    context 'pattern' do
      subject { create(:product_type, :pattern) }
      it      { is_expected.to be_pattern }
    end

    context 'not pattern' do
      subject { create(:product_type) }
      it      { is_expected.not_to be_pattern }
    end
  end

  describe "#kit?" do
    subject { create(:product_type_kit) }
    it      { is_expected.to be_kit }
  end

  describe "#gift_card?" do
    subject { create(:product_type_gift_card) }
    it      { is_expected.to be_gift_card }
  end

  describe "requires_supplier" do
    it "is true" do
      expect(subject.requires_supplier?).to be true
    end

    context "is_operational" do
      before { allow_any_instance_of(described_class).to receive_messages is_operational?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be false
      end
    end

    context "is_digital" do
      before { allow_any_instance_of(described_class).to receive_messages is_digital?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be false
      end
    end

    context "has an assembly definition" do
      before { allow_any_instance_of(described_class).to receive_messages container?: true }

      it "is false" do
        expect(subject.requires_supplier?).to be false
      end
    end
  end
end
