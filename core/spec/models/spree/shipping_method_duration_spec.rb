require 'spec_helper'
describe Spree::ShippingMethodDuration do

  context 'relations' do
    it { should have_many(:shipping_methods) }
  end

  context 'validations' do
    it { should validate_presence_of(:description) }
  end
end