require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe "#path_to_variant" do

    subject { helper.path_to_variant(line_item, variant) }

    context "Flip on suites_feature is on" do
      let(:suite) { Spree::Suite.new(id: 21, permalink: 'suite-perma') }
      let(:tab) { Spree::SuiteTab.new(id: 22, tab_type: 'tab-type') }
      let(:variant) { Spree::Variant.new(number: "V1234") }
      let(:line_item) { Spree::LineItem.new(variant: variant, suite: suite, suite_tab: tab) }

      let(:suite_class) { double('Suite', find_by: nil) }
      let(:suite_tab_class) { double('SuiteTab', find_by: nil) }

      before do
        allow(Flip).to receive(:on?).with(:suites_feature).and_return(true)
        allow(Spree::Suite).to receive(:unscoped).and_return suite_class
        allow(Spree::SuiteTab).to receive(:unscoped).and_return suite_tab_class
      end

      context "when both suite and tab are present" do
        before do
          allow(suite_class).to receive(:find_by).with(id: 21).and_return suite
          allow(suite_tab_class).to receive(:find_by).with(id: 22).and_return tab
        end

        context "when assembly definition is not present on the variant" do
          it "should give a full link to suite tab with the variant number" do
            expect(subject).to eq spree.suite_path(id: 'suite-perma', tab: 'tab-type', variant_id: 'V1234')
          end
        end

        context "when assembly definition is present on the variant" do
          before {variant.assembly_definition = Spree::AssemblyDefinition.new }

          it "should give a link to suite tab without the variant" do
            expect(subject).to eq spree.suite_path(id: 'suite-perma', tab: 'tab-type')
          end
        end

      end

      context "when only the suite is present" do
        before { allow(suite_class).to receive(:find_by).with(id: 21).and_return suite }

        it "should give a full link to suite only" do
          expect(subject).to eq spree.suite_path(id: 'suite-perma')
        end
      end

      context "when no suite can be found" do
        it "should not link to anywhere" do
          expect(subject).to eq '#'
        end
      end

    end

    context "Flip on suites_feature is off" do
      let(:product_page) { create(:product_page) }
      let(:product_page_tab_kit) { product_page.knit_your_own }
      let(:product_page_tab) { product_page.made_by_the_gang }
      let(:variant) { build(:variant) }
      let(:line_item) {create(:line_item, product_page: product_page, product_page_tab: product_page_tab)}

      before { allow(Flip).to receive(:on?).with(:suites_feature).and_return(false) }

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
        it { should eq "#" }
      end

      context "when product_page_tab is nil" do
        before { line_item.product_page_tab = nil }
        it { should eq "/shop/items/#{product_page.permalink}" }
      end
    end


  end
end
