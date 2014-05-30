require 'spec_helper'

describe Spree::ProductPageDecorator, type: :decorator do
  let(:product_group) { create(:product_group) }
  let(:women)         { create(:target, name: 'women') }
  let(:product_page_tab) { create(:product_page_tab)}
  let(:product_page_tab_kit) { create(:product_page_tab_kit)}
  let(:product_page) { create(:product_page, product_groups: [product_group], target: women, tabs: [ product_page_tab, product_page_tab_kit]) }
  let(:decorator) { product_page.decorate( context: { selected_tab: product_page_tab } ) }
  let(:product_page_kit_tab_selected) { product_page.decorate( context: { selected_tab: product_page_tab_kit } ) }

  subject { decorator }

  context "selected_tab" do

    it "returns the selected tab" do
      expect(subject.selected_tab).to eq(product_page_tab)
    end

    it "returns made by the gang tab when nothing is set" do
      expect(product_page.decorate.selected_tab).to eq(product_page_tab)
    end

  end

  context "inverted_colour" do

    it "returns inverted" do
      expect(product_page_kit_tab_selected.inverted_colour).to eq('inverted')
    end

    it "returns nil" do
      expect(subject.inverted_colour).to be_nil
    end

  end

  context "made_by_the_gang_active_class" do

    it "returns ''" do
      expect(product_page_kit_tab_selected.made_by_the_gang_active_class).to eq('')
    end

    it "returns active" do
      expect(subject.made_by_the_gang_active_class).to eq('active')
    end

  end

  context "knit_your_own_active_class" do

    it "returns ''" do
      expect(subject.knit_your_own_active_class).to eq('')
    end

    it "returns active" do
      expect(product_page_kit_tab_selected.knit_your_own_active_class).to eq('active')
    end

  end

  context "row_hero_type" do

    it "returns ' made-by-the-gang'" do
      expect(subject.row_hero_type).to eq(' made-by-the-gang')
    end

    it "returns ' knit-your-own'" do
      expect(product_page_kit_tab_selected.row_hero_type).to eq(' knit-your-own')
    end

  end

  context "made_by_the_gang_tab" do

    it "returns tab " do
      expect(subject.made_by_the_gang_tab).to eq(product_page_tab)
    end
  end

  context "knit_your_own_tab" do

    it "returns tab " do
      expect(subject.knit_your_own_tab).to eq(product_page_tab_kit)
    end

  end

  context "url_encode_tab_name" do

    it "returns made-by-the-gang" do
      expect(subject.url_encode_tab_name(product_page_tab)).to eq('made-by-the-gang')
    end


    it "returns knit-your-own" do
      expect(subject.url_encode_tab_name(product_page_tab_kit)).to eq('knit-your-own')
    end

  end

  context "url_encoded_product_page_url" do

    it "returns made-by-the-gang" do
      expected =  "http://www.example.com//shop/items/#{product_page.permalink}/made-by-the-gang"
      actual =  URI.unescape(subject.url_encoded_product_page_url(product_page_tab))
      expect(actual).to eq(expected)
    end

    it "returns knit-your-own" do
      expected =  "http://www.example.com//shop/items/#{product_page.permalink}/knit-your-own"
      actual =  URI.unescape(subject.url_encoded_product_page_url(product_page_tab_kit))
      expect(actual).to eq(expected)
    end

  end


  describe "only items in stock are displayed" do
    subject { decorator }
    let(:variants_in_stock)    { build_list(:base_variant,2) }

    before do
      allow(product_page).to receive(:displayed_variants_in_stock) { variants_in_stock}
    end
    its(:made_by_the_gang_variants) { should match_array(variants_in_stock)}
  end

  describe "tags" do
    subject { decorator }
    let(:visible_tag_names) { %w(one two) }

    before do
      allow(product_page).to receive(:visible_tag_names).and_return(visible_tag_names)
    end

    its(:tags) { should match_array(visible_tag_names) }
  end

  describe "decorated_first_knit_your_own_product_variant" do
    subject { decorator }
    let(:kit) { create(:product, product_group: product_group, product_type: create(:product_type_kit)) }
    let(:men)           { create(:target, name: 'men') }
    let!(:women_variant) { create(:variant, product: kit, target: women) }
    let!(:men_variant)   { create(:variant, product: kit, target: men) }

    before :each do
      product_page.kit = kit
    end

    its(:decorated_first_knit_your_own_product_variant) { should eq(women_variant) }
  end

  describe "tab banners" do
    let(:tab) { product_page.tabs.first }
    subject { decorator }

    context "when the made by the gang tab has no image" do
      before :each do
        allow(product_page).to receive(:made_by_the_gang).and_return(tab)
        allow(tab).to receive(:banner_url).and_return(nil)
      end

      its(:made_by_the_gang_banner?) { should be_false }
      its(:made_by_the_gang_banner_url) { should be_nil }
    end

    context "when the made by the gang tab has an image" do
      before :each do
        allow(product_page).to receive(:made_by_the_gang).and_return(tab)
        allow(tab).to receive(:banner_url).and_return("made-by-the-gang-banner-url")
      end

      its(:made_by_the_gang_banner?) { should be_true }
      its(:made_by_the_gang_banner_url) { should eq("made-by-the-gang-banner-url") }
    end

    context "when the knit_your_own tab has no image" do
      before :each do
        allow(product_page).to receive(:knit_your_own).and_return(tab)
        allow(tab).to receive(:banner_url).and_return(nil)
      end

      its(:knit_your_own_banner?) { should be_false }
      its(:knit_your_own_banner_url) { should be_nil }
    end

    context "when the knit_your_own tab has an image" do
      before :each do
        allow(product_page).to receive(:knit_your_own).and_return(tab)
        allow(tab).to receive(:banner_url).and_return("knit_your_own-banner-url")
      end

      its(:knit_your_own_banner?) { should be_true }
      its(:knit_your_own_banner_url) { should eq("knit_your_own-banner-url") }
    end
  end

  describe "hero_data_attributes" do
    subject { decorator.hero_data_attributes }

    context "with banners and colours for both tabs" do
      before :each do
        allow(decorator).to receive(:made_by_the_gang_banner?).and_return(true)
        allow(decorator).to receive(:made_by_the_gang_banner_url).and_return("made-by-the-gang-url")
        allow(decorator).to receive(:made_by_the_gang_background_color?).and_return(true)
        allow(decorator).to receive(:made_by_the_gang_background_color).and_return("made-by-the-gang-color")
        allow(decorator).to receive(:knit_your_own_banner?).and_return(true)
        allow(decorator).to receive(:knit_your_own_banner_url).and_return("knit-your-own-url")
        allow(decorator).to receive(:knit_your_own_background_color?).and_return(true)
        allow(decorator).to receive(:knit_your_own_background_color).and_return("knit-your-own-color")
      end

      it { should match(%r{\bdata-hero-made-by-the-gang="made-by-the-gang-url"(\s|$)}) }
      it { should match(%r{\bdata-hero-knit-your-own="knit-your-own-url"(\s|$)}) }
      it { should match(%r{\bdata-hero-made-by-the-gang-colour="made-by-the-gang-color"(\s|$)}) }
      it { should match(%r{\bdata-hero-knit-your-own-colour="knit-your-own-color"(\s|$)}) }
    end

    context "with a banner for made by the gang only" do
      before :each do
        allow(decorator).to receive(:made_by_the_gang_banner?).and_return(true)
        allow(decorator).to receive(:made_by_the_gang_banner_url).and_return("made-by-the-gang-url")
      end

      it { should match(%r{\bdata-hero-made-by-the-gang="made-by-the-gang-url"(\s|$)}) }
      it { should_not match(%r{\bdata-hero-knit-your-own=".*"(\s|$)}) }
      it { should_not match(%r{\bdata-hero-made-by-the-gang-colour=".*"(\s|$)}) }
      it { should_not match(%r{\bdata-hero-knit-your-own-colour=".*"(\s|$)}) }
    end


    context "with a banner for knit_your_own only" do
      before :each do
        allow(decorator).to receive(:knit_your_own_banner?).and_return(true)
        allow(decorator).to receive(:knit_your_own_banner_url).and_return("knit-your-own-url")
      end

      it { should_not match(%r{\bdata-hero-made-by-the-gang=".*"(\s|$)}) }
      it { should match(%r{\bdata-hero-knit-your-own="knit-your-own-url"(\s|$)}) }
      it { should_not match(%r{\bdata-hero-made-by-the-gang-colour=".*"(\s|$)}) }
      it { should_not match(%r{\bdata-hero-knit-your-own-colour=".*"(\s|$)}) }
    end

  end
end
