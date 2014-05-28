require 'spec_helper'

describe Spree::ProductPageTab do
  subject { create(:product_page).tabs.first }

  its(:banner_mini_url) { should be_nil }
  its(:banner_url) { should be_nil }
  its(:position) { should eq(0) }

  it "should assign its position automatically" do
    expect(subject.product_page.tabs.last.position).to eq(1)

    product_page2 = create(:product_page)
    expect(product_page2.tabs.first.position).to eq(0)
    expect(product_page2.tabs.last.position).to eq(1)
  end

  context "product page tab types" do

    it "work when tab type is made by the gang " do
      subject.tab_type = Spree::ProductPageTab::MADE_BY_THE_GANG
      expect(subject.made_by_the_gang?).to be_true
      expect(subject.knit_your_own?).to be_false
    end

    it "work when tab type is knit your own" do
      subject.tab_type = Spree::ProductPageTab::KNIT_YOUR_OWN
      expect(subject.made_by_the_gang?).to be_false
      expect(subject.knit_your_own?).to be_true
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

    its(:banner_url) { should eq("image-url") }
    its(:banner_mini_url) { should eq("mini-image-url") }
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
end
