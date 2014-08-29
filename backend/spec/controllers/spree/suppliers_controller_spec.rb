require 'spec_helper'

describe Spree::Admin::SuppliersController, type: :controller do
  let(:supplier) {create(:supplier)}
  stub_authorization!

  it 'can edit supplier' do
    spree_get :edit, id: supplier.permalink
    expect(response).to be_success
    expect(assigns(:supplier)).to eq(supplier)
  end

  context "new" do

    it 'sets defaults' do
      Spree::Supplier.should_receive(:default_mid_code).and_return('foo')
      country = mock_model(Spree::Country)
      Spree::Supplier.should_receive(:default_country).and_return(country)

      spree_get :new
      expect(response).to be_success
      expect(assigns(:supplier)).to be_kind_of(Spree::Supplier)
      expect(assigns(:supplier).mid_code).to eq 'foo'
      expect(assigns(:supplier).country).to eq country
    end

  end


end
