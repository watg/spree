require 'spec_helper'

describe Spree::ProductPageTab do
  subject { create(:product_page).tabs.first }

  describe '#banner_mini_url' do
    subject { super().banner_mini_url }
    it { is_expected.to be_nil }
  end

  describe '#banner_url' do
    subject { super().banner_url }
    it { is_expected.to be_nil }
  end

  describe '#position' do
    subject { super().position }
    it { is_expected.to eq(0) }
  end

  it "should assign its position automatically" do
    expect(subject.product_page.tabs.last.position).to eq(1)

    product_page2 = create(:product_page)
    expect(product_page2.tabs.first.position).to eq(0)
    expect(product_page2.tabs.last.position).to eq(1)
  end

  context "product page tab types" do

    it "work when tab type is made by the gang " do
      subject.tab_type = Spree::ProductPageTab::MADE_BY_THE_GANG
      expect(subject.made_by_the_gang?).to be true
      expect(subject.knit_your_own?).to be false
    end

    it "work when tab type is knit your own" do
      subject.tab_type = Spree::ProductPageTab::KNIT_YOUR_OWN
      expect(subject.made_by_the_gang?).to be false
      expect(subject.knit_your_own?).to be true
    end

  end

  context "url_safe_tab_type" do
    it "should replace _ with -" do
      expect(subject.url_safe_tab_type).to eq("made-by-the-gang")
    end
  end

  context "to_tab_type" do
    it "should replace - with _" do
      expect(subject.class.to_tab_type("made-by-the-gang")).to eq("made_by_the_gang")
    end
  end

  context "with an image" do
    let(:attachment) { double }
    let(:image) { double(attachment: attachment) }

    before do
      allow(subject).to receive(:image).and_return(image)
      allow(attachment).to receive(:url).with(:large).and_return("image-url")
      allow(attachment).to receive(:url).with(:mini).and_return("mini-image-url")
    end

    describe '#banner_url' do
      subject { super().banner_url }
      it { is_expected.to eq("image-url") }
    end

    describe '#banner_mini_url' do
      subject { super().banner_mini_url }
      it { is_expected.to eq("mini-image-url") }
    end
  end

  describe "background_color_code" do
    it "checks for a hex color code" do
      subject.background_color_code = "123"
      expect(subject).to be_invalid
      subject.background_color_code = "14J02P"
      expect(subject).to be_invalid
      subject.background_color_code = "A4A4A4"
      expect(subject).to be_valid
      subject.background_color_code = "e4ff68"
      expect(subject).to be_valid
    end
  end

  context "touching" do

    let(:product_page) { create(:product_page) }
    let(:product_page_tab) { create(:product_page_tab, product_page: product_page) }

    it "updates a product_page" do
      product_page.update_column(:updated_at, 1.day.ago)
      product_page_tab.reload.touch
      expect(product_page.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end

  end

end
