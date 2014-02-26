require 'spec_helper'

describe Spree::Admin::ProductPagesHelper, type: :helper do

  describe "#tab_title" do
    subject { helper.tab_type(tab) }

    context "for made by the gang" do
      let(:tab) { create(:product_page_tab, tab_type: 'made_by_the_gang') }
      it { should eq("Made by the gang / accessories") }
    end

    context "for knit your own" do
      let(:tab) { create(:product_page_tab, tab_type: 'knit_your_own') }
      it { should eq("Knit your own") }
    end
  end
end
