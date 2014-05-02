require 'spec_helper'

describe Spree::IndexPageItem do

  context 'validation' do
    let(:index_page) { create(:index_page) }
    let(:product_page) { create(:product_page) }
    let(:params) { {index_page: index_page, product_page: product_page} }

    let!(:existing) { create(:index_page_item, params) }

    context "adding the same product page after deleting the first" do
      before { existing.delete }
      subject { build(:index_page_item, params) }
      it { should be_valid }
    end

    context "adding the same product page with different variants" do
      let(:variant) { create(:variant) }
      subject { build(:index_page_item, params.merge(variant: variant)) }

      it { should be_valid }
    end

    context "adding the same variant with different product pages" do
      let(:variant) { create(:variant) }
      let(:new_product_page) { create(:product_page) }
      subject { build(:index_page_item, params.merge(product_page: new_product_page, variant: variant)) }

      before :each do
        existing.variant = variant
        existing.save
      end

      it { should be_valid }
    end
  end
end
