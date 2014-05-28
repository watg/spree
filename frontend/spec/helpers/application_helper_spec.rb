require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe "#path_to_variant" do
    let(:product_page) { create(:product_page) }
    let(:product_page_tab_kit) { product_page.knit_your_own }
    let(:product_page_tab) { product_page.made_by_the_gang }
    let(:variant) { build(:variant) }
    let(:line_item) {create(:line_item, product_page: product_page, product_page_tab: product_page_tab)}

    subject { helper.path_to_variant(line_item, variant) }

    context "when tab is made by the gang" do
      it { should eq "/shop/items/#{product_page.permalink}/made-by-the-gang" }
     end

    context "when tab is knit your own" do
      before { line_item.product_page_tab = product_page_tab_kit }
      it { should eq "/shop/items/#{product_page.permalink}/knit-your-own" }
     end

    context "when product_page is deleted" do
      before { product_page.deleted_at = Time.now }
      it { should eq "/shop/items/#{product_page.permalink}/made-by-the-gang" }
     end

    context "when product_page_tab is deleted" do
      before { product_page_tab.deleted_at = Time.now }
      it { should eq "/shop/items/#{product_page.permalink}/made-by-the-gang" }
     end

    context "when product_page is nil" do
      before { line_item.product_page = nil }
      it { should eq "/shop/items/not-found/made-by-the-gang" }
    end

    context "when product_page_tab is nil" do
      before { line_item.product_page_tab = nil }
      it { should eq "/shop/items/#{product_page.permalink}" }
    end

  end
end
