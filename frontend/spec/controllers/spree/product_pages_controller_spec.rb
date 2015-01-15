require 'spec_helper'

describe Spree::ProductPagesController, type: :controller do
  describe "GET show" do
    context '#redirect_to_suites_pages' do
      let!(:redirection_service_result) { double(valid?: true, result: {url: 'http://url.com', http_code: 301}) }

      before do
        allow(Flip).to receive(:on?).with(:suites_feature).and_return(true)
      end

      it "uses the SuitePageRedirectionService to redirect to a suite" do
        expect(Spree::SuitePageRedirectionService).to receive(:run).
          with(permalink: 'product-page-permalink', params: { "tab" => 'made-by-the-gang'}).
          and_return redirection_service_result

        spree_get :show, :id => 'product-page-permalink', :tab => "made-by-the-gang"
        expect(response).to redirect_to('http://url.com')
        expect(response.status).to eq 301
      end
    end
  end
end
