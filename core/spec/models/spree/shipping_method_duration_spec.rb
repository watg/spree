require 'spec_helper'
describe Spree::ShippingMethodDuration do

  context 'relations' do
    it { expect(subject).to have_many(:shipping_methods) }
  end
end