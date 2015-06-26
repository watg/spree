require "spec_helper"

describe ApplicationHelper, type: :helper do
  describe "#path_to_variant" do
    subject { helper.path_to_variant(line_item, variant) }

    let(:suite) { Spree::Suite.new(id: 21, permalink: "suite-perma") }
    let(:tab) { Spree::SuiteTab.new(id: 22, tab_type: "tab-type") }
    let(:variant) { Spree::Variant.new(number: "V1234") }
    let(:line_item) { Spree::LineItem.new(variant: variant, suite: suite, suite_tab: tab) }

    let(:suite_class) { double("Suite", find_by: nil) }
    let(:suite_tab_class) { double("SuiteTab", find_by: nil) }

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

      context "when variant is not the master" do
        before { variant.is_master = false }
        it "gives a full link to suite tab with the variant number" do
          path = spree.suite_path(id: "suite-perma", tab: "tab-type", variant_id: "V1234")
          expect(subject).to eq path
        end
      end

      context "when variant is the master" do
        before { variant.is_master = true }

        it "gives a link to suite tab without the variant" do
          expect(subject).to eq spree.suite_path(id: "suite-perma", tab: "tab-type")
        end
      end
    end

    context "when only the suite is present" do
      before { allow(suite_class).to receive(:find_by).with(id: 21).and_return suite }

      it "gives a full link to suite only" do
        expect(subject).to eq spree.suite_path(id: "suite-perma")
      end
    end

    context "when no suite can be found" do
      it "does not link to anywhere" do
        expect(subject).to eq "#"
      end
    end
  end # end #path_to_variant
end
