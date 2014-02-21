require 'spec_helper'

describe Spree::ProductsController, type: :controller do
  let(:product) { create(:product_with_variants_displayable, product_type: :kit) }
  let(:variant) { product.variants.first }
  let(:params)  { valid_params } 
  let(:order)   { create(:order_with_pending_payment) }
  
  before do
    allow(Flip).to receive(:product_pages?) { false }
    subject.stub :authorize! => true, :ensure_api_key => true
    subject.stub(:current_order).and_return(order)
    subject.stub(:set_current_order).and_return(order)
    Spree::Product.stub :find_by_permalink! => product
    allow(Spree::VariantStockControlService).to receive(:run).with(selected_variant: variant) { 
      OpenStruct.new(result: {redirect_to: nil} )
    }
  end

  it "should find selected variant from params option_values" do
    Spree::Variant.should_receive(:options_by_product).with(product, ['Magic-Mint','Large']).and_return(product.variants[0])
    spree_get :show, params
    expect(response.status).to eq(200)
  end

  context "stock level" do
    before do
      allow(Spree::Variant).to receive(:options_by_product) { variant }
      allow(Spree::VariantStockControlService).to receive(:run).with(selected_variant: variant) { 
        OpenStruct.new(result: {redirect_to: '/products/other/blue-large', message: 'selected_variant no in stock. redirected to other product'} )
      }
    end
    it "redirects to a variant in stock" do
      spree_get :show, params
      expect(response.status).to eq(302) 
    end
  end


  context "Product Pages active" do
    before do
      allow(Flip).to receive(:product_pages?) { true }
      allow(Spree::ProductPageRedirectionService).to receive(:run) { OpenStruct.new(result: {url: '/new-product-pages/r2w/paul-1-0001', http_code: 301}) }
    end

    it 'redirects to new product pages' do
      spree_get :show, params

      expect(response.status).to eq(301)
      expect(response).to redirect_to('/new-product-pages/r2w/paul-1-0001')
    end
  end

  # ==================

  def valid_params
    {
      product_id: product.permalink,
      option_values: 'Magic-Mint/Large'
    }
  end
end
