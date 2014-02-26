require 'spec_helper'

describe Spree::Admin::ProductPagesController, type: :controller do
  stub_authorization!

  describe "#update" do
    let(:product_page) { create(:product_page) }
    let(:taxons)       { [create(:taxon)] }
    let(:target)       { create(:target) }
    let(:params) {
      {
        id: product_page.to_param,
        product_page: {
          "name"      => product_page.name,
          "title"     => product_page.title,
          "permalink" => product_page.permalink,
          "target_id" => target.to_param
        }
      }
    }

    let(:successful_outcome)   { OpenStruct.new(:success? => true) }
    let(:unsuccessful_outcome)   { OpenStruct.new(:success? => false, :errors => OpenStruct.new(:message_list => [])) }

    def do_action
      spree_put :update, params
    end

    it "runs the UpdateProductPageService" do
      expect(Spree::UpdateProductPageService).to receive(:run).
        with(product_page: product_page, details: params[:product_page]).
        and_return(successful_outcome)
      do_action
    end

    context "on success" do
      before :each do
        allow(Spree::UpdateProductPageService).to receive(:run).and_return(successful_outcome)
      end

      it "sets the flash message" do
        do_action
        expect(flash[:success]).to be_present
      end

      it "redirects to the index page" do
        do_action
        expect(response).to redirect_to(spree.edit_admin_product_page_path(product_page))
      end
    end

    context "on error" do
      before :each do
        allow(Spree::UpdateProductPageService).to receive(:run).and_return(unsuccessful_outcome)
      end

      it "sets the flash message" do
        do_action
        expect(flash[:error]).to be_present
      end

      it "redisplays to the edit page" do
        do_action
        expect(response).to redirect_to(spree.edit_admin_product_page_path(product_page))
      end
    end
  end
end
