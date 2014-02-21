require 'spec_helper'

describe Spree::BaseHelper, type: :helper do
  describe "#seo_url" do
    let(:taxon) { create(:taxon) }
    let!(:index_page) { create(:index_page, taxon: taxon) }
    subject { helper.seo_url(taxon) }

    # context "when product pages are enabled" do
    #   before { allow(Flip).to receive(:product_pages?).and_return(true) }
    #   it { should eq spree.index_page_path(taxon.permalink) }
    # end

    context "when product pages are disabled" do
      before { allow(Flip).to receive(:product_pages?).and_return(false) }
      it { should eq spree.nested_taxons_path(taxon.permalink) }
    end
  end
end
