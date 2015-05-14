require 'spec_helper'

describe Spree::SuiteTab do

  let(:suite) { build_stubbed(:suite)}
  let(:product) { build_stubbed(:product)}

  subject { Spree::SuiteTab.new(tab_type: "made-by-the-gang", suite: suite, product: product ) }

  it "should assign a position on create" do
    subject.save
    expect(subject.position).to eq 1
  end

  describe "#tab_types" do
    it "returns all the tab types" do
      expect(described_class.tab_types).to eq [
        "crochet-your-own",
        "knit-your-own",
        "knit-party",
        "made-by-the-gang",
        "gift-voucher",
        "knitting-pattern",
        "crochet-pattern",
        "yarn-and-wool",
        "knitting-supply",
        "default"
      ]
    end
  end

  describe "associations" do
    it { is_expected.to have_and_belong_to_many(:cross_sales) }
  end

  describe "#presentation" do
    its(:presentation) { should eq 'READY MADE' }

    context "knit-your-own" do
      before { subject.tab_type = 'knit-your-own' }
      its(:presentation) { should eq 'KNIT YOUR OWN' }
    end

    context "crochet-your-own" do
      before { subject.tab_type = 'crochet-your-own' }
      its(:presentation) { should eq 'CROCHET YOUR OWN' }
    end

    context "default" do
      before { subject.tab_type = 'default' }
      its(:presentation) { should eq 'GET IT!' }
    end

  end

  describe "#partial" do
    its(:partial) { should eq 'default' }

    context "knit-your-own" do
      before { subject.tab_type = 'knit-your-own' }
      its(:partial) { should eq 'knit_your_own' }
    end

    context "default" do
      before { subject.tab_type = 'default' }
      its(:partial) { should eq 'default' }
    end

  end

  context "setting the lowest amounts" do

    let(:suite_tab) { create(:suite_tab) }

    context "normal amount" do

      it "sets the amount" do
        suite_tab.set_lowest_normal_amount(100, 'USD')
        expect(suite_tab.lowest_normal_amount('USD')).to eq 100
      end

      it "updates an existing amount" do
        suite_tab.set_lowest_normal_amount(100, 'USD')
        suite_tab.set_lowest_normal_amount(200, 'USD')
        expect(suite_tab.lowest_normal_amount('USD')).to eq 200
      end

      it "can be scoped by currency" do
        suite_tab.set_lowest_normal_amount(100, 'GBP')
        suite_tab.set_lowest_normal_amount(200, 'USD')
        expect(suite_tab.lowest_normal_amount('GBP')).to eq 100
        expect(suite_tab.lowest_normal_amount('USD')).to eq 200
      end

    end

    context "sale amount" do

      it "sets the amount" do

        suite_tab.set_lowest_sale_amount(100, 'USD')
        expect(suite_tab.lowest_sale_amount('USD')).to eq 100

      end

      it "updates an existing amount" do

        suite_tab.set_lowest_sale_amount(100, 'USD')
        suite_tab.set_lowest_sale_amount(200, 'USD')
        expect(suite_tab.lowest_sale_amount('USD')).to eq 200

      end

      it "can be scoped by currency" do
        suite_tab.set_lowest_sale_amount(100, 'GBP')
        suite_tab.set_lowest_sale_amount(200, 'USD')
        expect(suite_tab.lowest_sale_amount('GBP')).to eq 100
        expect(suite_tab.lowest_sale_amount('USD')).to eq 200
      end

    end
  end


  context "touching" do

    let(:suite) { create(:suite) }
    let(:suite_tab) { Spree::SuiteTab.create(suite: suite, product: product) }

    it "updates a suite" do
      suite.update_column(:updated_at, 1.day.ago)
      suite_tab.reload.touch
      expect(suite.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end

  end
end
