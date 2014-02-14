require 'spec_helper'

describe Spree::Admin::IndexPageItemsController,  type: :controller do
  stub_admin_user
  let(:index_page) { create(:index_page) }

  describe "POST #create" do
    let(:product_page) { create(:product_page) }

    def do_action
      spree_post(:create,
        index_page_id: index_page.to_param,
        index_page_item: {
          title: "some title",
          product_page_id: product_page.id,
          variant_id: ""
        })
    end

    it "redirects to the index page" do
      do_action
      expect(response).to redirect_to(spree.edit_admin_index_page_path(index_page))
    end

    it "creates a new index page item" do
      expect { do_action }.to change(Spree::IndexPageItem, :count).by(1)
    end

    it "sets the title" do
      do_action
      item = Spree::IndexPageItem.last
      expect(item.title).to eq("some title")
    end

    it "sets the product_page" do
      do_action
      item = Spree::IndexPageItem.last
      expect(item.product_page).to eq(product_page)
    end
  end
end
