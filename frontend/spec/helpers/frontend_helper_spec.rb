require 'spec_helper'

module Spree
  describe FrontendHelper, :type => :helper do
    # Regression test for #2759
    it "nested_taxons_path works with a Taxon object" do
      taxon = create(:taxon, :name => "iphone")
      expect(spree.nested_taxons_path(taxon)).to eq("/t/iphone")
    end

    describe "#my_bag_link" do
      before do
        allow(helper).to receive(:simple_current_order).and_return(nil)
      end

      it "returns a link to My Bag" do
        expect(helper.my_bag_link).to eq "<a class=\"cart-info empty\" href=\"/cart\">My Bag: (Empty)</a>"
      end
    end

    describe "#my_bag_link_mobile" do
      context "when there is no order" do
        let(:order) { nil }
        before { allow(helper).to receive(:simple_current_order).and_return(order) }

        it "returns a link to My Bag" do
          expect(helper.my_bag_link_mobile).to eq "<a class=\"link-cart\" href=\"/cart\">0</a>"
        end
      end

      context "when the number of items are nil" do
        let(:order) { double("Order", item_count: nil) }
        before { allow(helper).to receive(:simple_current_order).and_return(order) }

        it "returns a link to My Bag" do
          expect(helper.my_bag_link_mobile).to eq "<a class=\"link-cart\" href=\"/cart\">0</a>"
        end
      end

      context "when the number of items are 0" do
        let(:order) { double("Order", item_count: 0) }
        before { allow(helper).to receive(:simple_current_order).and_return(order) }

        it "returns a link to My Bag" do
          expect(helper.my_bag_link_mobile).to eq "<a class=\"link-cart\" href=\"/cart\">0</a>"
        end
      end

      context "when the number of items are 0" do
        let(:order) { double("Order", item_count: 2) }
        before { allow(helper).to receive(:simple_current_order).and_return(order) }

        it "returns a link to My Bag" do
          expect(helper.my_bag_link_mobile).to eq "<a class=\"link-cart\" href=\"/cart\">2</a>"
        end
      end
    end
  end
end
