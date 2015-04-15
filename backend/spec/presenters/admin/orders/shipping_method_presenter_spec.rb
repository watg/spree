require 'spec_helper'

describe ::Admin::ShippingMethodPresenter, type: :presenter do
  let(:admin_name) { 'foo' }
  let(:shipping_method) do 
    mock_model(Spree::ShippingMethod, admin_name: admin_name, name: 'UPS Ground')
  end

  subject { described_class.new(shipping_method, {}) }

  context "with admin name" do
    it "displays the correct name" do
      expect(subject.display_name).to eq 'UPS Ground (foo)'
    end

    context "without internal name" do
      let(:admin_name) { '' }
      it "displays the correct name" do
        expect(subject.display_name).to eq 'UPS Ground'
      end
    end
  end

end

