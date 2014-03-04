require 'spec_helper'

describe Spree::ProductsController do
  let!(:product) { create(:product, :available_on => 1.year.from_now) }

  # not any more relevant due to the new product pages
  # it "should provide the current user to the searcher class" do
  #   user = mock_model(Spree.user_class, :last_incomplete_spree_order => nil, :spree_api_key => 'fake')
  #   controller.stub :spree_current_user => user
  #   Spree::Config.searcher_class.any_instance.should_receive(:current_user=).with(user)
  #   spree_get :index
  #   response.status.should == 200
  # end

  # Regression test for #2249
  it "doesn't error when given an invalid referer" do
    current_user = mock_model(Spree.user_class, :has_spree_role? => true, :last_incomplete_spree_order => nil, :generate_spree_api_key! => nil)
    controller.stub :spree_current_user => current_user
    request.env['HTTP_REFERER'] = "not|a$url"

    # Previously a URI::InvalidURIError exception was being thrown
    lambda { spree_get :show, :id => product.to_param }.should_not raise_error
  end

  # Regression tests for #2308 & Spree::Core::ControllerHelpers::SSL
  context "force_ssl enabled" do
    context "receive a SSL request" do
      before do
        request.env['HTTPS'] = 'on'
      end

      it "should not redirect to http" do
        #controller.should_not_receive(:redirect_to)
        spree_get :index
        request.protocol.should eql('https://')
      end
    end
  end

  context "redirect_https_to_http enabled" do
    before do
      reset_spree_preferences do |config|
        config.allow_ssl_in_development_and_test = true
        config.redirect_https_to_http = true
      end
    end

    context "receives a non SSL request" do
      it "should not redirect" do
        #controller.should_not_receive(:redirect_to)
        spree_get :index
        request.protocol.should eql('http://')
      end
    end

    context "receives a SSL request" do
      before do
        request.env['HTTPS'] = 'on'
        request.path = "/products?foo=bar"
      end

      it "should redirect to http" do
        spree_get :index
        response.should redirect_to("http://#{request.host}/products?foo=bar")
        response.status.should == 301
      end
    end
  end


	context "Flip stuff" do
	  let(:product) { create(:product_with_variants_displayable, product_type: :kit) }
	  let(:variant) { product.variants.first }
	  let(:params)  { {product_id: product.permalink,option_values: 'Magic-Mint/Large' } } 
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

  end



end
