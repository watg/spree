require 'spec_helper'
describe Spree::ShippingMethodDuration do

  context 'relations' do
    it { expect(subject).to have_many(:shipping_methods) }
  end

  context 'without a min value' do
    subject {build_stubbed(:shipping_method_duration, min: nil , max: 4 )}
    describe ".description" do
      it { expect(subject.description).to eq("up to 4 days") }
    end
  end

  context 'without a max value' do
    subject {build_stubbed(:shipping_method_duration, min: 4 , max: nil )}
    describe ".description" do
      it { expect(subject.description).to eq("in a few days") }
    end
  end

  context 'without a max or a min value' do
    subject {build_stubbed(:shipping_method_duration, min: nil , max: nil)}
    describe ".description" do
      it { expect(subject.description).to eq("in a few days") }
    end
  end

  context 'with a max and a min value' do
    subject {build_stubbed(:shipping_method_duration, min: 3 , max: 4 )}
    describe ".description" do
      it { expect(subject.description).to eq("3-4 days") }
    end
  end
end