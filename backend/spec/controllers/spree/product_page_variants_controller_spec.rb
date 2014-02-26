require 'spec_helper'

describe Spree::Admin::ProductPageVariantsController, type: :controller do
  stub_authorization!
  let(:product_page) { create(:product_page) }

  describe "GET #index" do
    let(:product_group) { create(:product_group) }
    let(:kit) { create(:product, product_group: product_group, product_type: "kit")}
    let(:kit_variants) { 2.times.map { create(:variant, product: kit) } }
    let(:r2w_product) { create(:product, product_group: product_group, product_type: "made_by_the_gang")}
    let(:r2w_variants) { 2.times.map { create(:variant, product: r2w_product) } }
    let(:variants) { kit_variants + r2w_variants }

    def do_action
      spree_get :index, product_page_id: product_page.permalink
    end

    it "is successful" do
      do_action
      expect(response).to be_success
    end

    it "assigns the product group" do
      do_action
      expect(assigns[:product_page]).to eq(product_page)
    end

    it "assigns all available variants" do
      allow(Spree::ProductPage).to receive(:find_by).with(permalink: product_page.to_param).and_return(product_page)
      allow(product_page).to receive(:available_variants).and_return(variants)

      do_action
      expect(assigns[:available_variants]).to eq(variants)
    end

    it "assigns the product_page_variants" do
      allow(Spree::ProductPage).to receive(:find_by).with(permalink: product_page.to_param).and_return(product_page)
      allow(product_page).to receive(:displayed_variants).and_return(variants)
      do_action
      expect(assigns[:displayed_variants]).to eq(variants)
    end
  end

  describe "POST #update_positions" do
    let(:variants) { create_list(:variant, 2) }
    let(:positions) {
      { variants[0].to_param => "5", variants[1].to_param => "9" }
    }

    before :each do
      product_page.displayed_variants = variants
    end

    def do_action
      spree_post :update_positions, product_page_id: product_page.to_param, positions: positions
    end

    it "is successful" do
      do_action
      expect(response).to be_successful
    end

    it "sets the position of each product page variant" do
      do_action
      product_page.reload
      new_positions = product_page.product_page_variants.inject({}) do |h, v|
        h[v.variant_id.to_s] = v.position.to_s
        h
      end
      expect(new_positions).to eq(positions)
    end
  end

  describe "POST #create" do
    let(:outcome) { OpenStruct.new(success?: true)}
    let(:variant_id) { "2" }

    before :each do
      allow(Spree::CreateProductPageVariantsService).to receive(:run).and_return(outcome)
    end

    def do_action
      spree_post :create, product_page_id: product_page.to_param, variant_id: variant_id, format: :js
    end

    it "calls the ProductPageVariantService" do
      expected_params = {
        product_page: product_page,
        variant_id: variant_id,
      }
      expect(Spree::CreateProductPageVariantsService).to receive(:run).with(expected_params).and_return(outcome)
      do_action
    end

    context "on success" do
      it "renders the to the create js" do
        do_action
        expect(response).to render_template("create")
      end

      it "assigns the variant id" do
        do_action
        expect(assigns[:variant_id]).to eq(variant_id)
      end
    end

    context "on error" do
      let(:errors) { OpenStruct.new(message_list: ["error1", "error2"]) }
      let(:outcome) { OpenStruct.new(success?: false, errors: errors)}

      it "is not successful" do
        do_action
        expect(response.status).to eq(422)
      end

      it "returns the errors" do
        do_action
        expect(response.body).to eq("error1<br/>error2")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:variant) { create(:variant) }

    before :each do
      product_page.displayed_variants << variant
    end

    def do_action(variant_id = variant.id)
      spree_delete :destroy, product_page_id: product_page.to_param, id: variant_id, format: :js
    end

    it "removes the variant from the product page" do
      do_action
      expect(product_page.reload.displayed_variants).to_not include(variant)
    end

    it "renders the delete js" do
      do_action
      expect(response).to render_template("destroy")
    end

    it "assigns the variant id" do
      do_action
      expect(assigns[:variant_id]).to eq(variant.id)
    end
  end
end
