require 'spec_helper'
describe Spree::ShippingMethodDuration do

  context 'relations' do
    it { expect(subject).to have_many(:shipping_methods) }
  end

  context 'validations' do
    it { expect(subject).to validate_presence_of(:description) }
  end
end