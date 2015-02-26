require 'spec_helper'
describe Spree::Api::DashboardController , :type => :controller do
  render_views

  before do
    stub_authentication!
  end

  subject { Spree::Api::DashboardController }

  let!(:product) { create(:product) }
  let!(:variant) {  create(:variant, product: product)  }

  describe '#last_bought_product'  do
    before do
      allow(Spree::Order).to receive(:where).with('completed_at is not null').and_return([product])
      api_get :last_bought_product
    end

    it 'respond with the last bought product' do
      expect(json_response['name']).to eql(product.name)
      expect(json_response['marketing_type']).to eql(product.marketing_type.title)
    end

    it 'response should have name key' do
      expect(json_response).to have_key(:name)
    end

    it 'response should have marketing_type key' do
      expect(json_response).to have_key(:marketing_type)
    end

    it 'response should have image_url key' do
      expect(json_response).to have_key(:image_url)
    end
  end

  describe '#today_sells' do
    before do
      api_get :today_sells
    end

    it 'response should have EUR key' do
      expect(json_response).to have_key(:EUR)
    end

    it 'response should have GBP key' do
      expect(json_response).to have_key(:GBP)
    end

    it 'response should have USD key' do
      expect(json_response).to have_key(:USD)
    end
  end

  describe '#today_orders' do
    before do
      api_get :today_orders
    end

    it 'response should have total key' do
      expect(json_response).to have_key(:total)
    end
  end

end
