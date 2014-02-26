require 'spec_helper'

describe Spree::Admin::IndexPageHelper, type: :helper do
  let(:item) { create(:product_page) }

  describe "#item_name" do
    subject { helper.item_name(item) }

    it { should eq("Product Page") }
  end

  describe "#item_class" do
    subject { helper.item_class(item) }

    it { should eq("product-page") }
  end
end
