require 'spec_helper'

describe Spree::SuitePresenter do

  let(:target) { mock_model(Spree::Target) }
  let(:suite) { create(:suite, target: target ) }
  let!(:tab) { suite.tabs.create(tab_type: 'arbitrary') }
  let!(:device) { :desktop }
  let(:context) { { currency: 'USD', device: device}}
  subject { described_class.new(suite, view, context) }

  before { allow(view).to receive(:current_currency).and_return 'USD' }

  it "should give us an out of stock message" do
    expect(subject.send(:render_out_of_stock)).to eq('<span class="price" itemprop="price">out-of-stock</span>')
  end

  describe "#tabs" do
    let!(:tab_in_stock) { create(:suite_tab, suite: suite, in_stock_cache: true)}
    let!(:tab_not_in_stock) { create(:suite_tab, suite: suite, in_stock_cache: false)}

    it "should give you only the tabs in stock" do
      expect(subject.tabs).to eq [tab_in_stock]
    end
  end

  describe "#desktop_image_size" do

    it "is large when the counter is 0" do
      expect(described_class.desktop_image_size(0)).to eq :large
    end

    it "is large when the counter is a modulus of 9" do
      expect(described_class.desktop_image_size(9)).to eq :large
      expect(described_class.desktop_image_size(18)).to eq :large
      expect(described_class.desktop_image_size(27)).to eq :large
    end

    it "is small when the counter is a not a modulus of 9" do
      expect(described_class.desktop_image_size(1)).to eq :small
      expect(described_class.desktop_image_size(2)).to eq :small
      expect(described_class.desktop_image_size(3)).to eq :small
      expect(described_class.desktop_image_size(4)).to eq :small
      expect(described_class.desktop_image_size(5)).to eq :small
      expect(described_class.desktop_image_size(6)).to eq :small
      expect(described_class.desktop_image_size(7)).to eq :small
      expect(described_class.desktop_image_size(8)).to eq :small
      expect(described_class.desktop_image_size(10)).to eq :small
      expect(described_class.desktop_image_size(17)).to eq :small
    end
    
  end

  describe "#image_size" do

    context "desktop" do

      it "is large when the counter is 0" do
        expect(subject.send(:image_size, 0)).to eq :large
      end

      it "is large when the counter is a modulus of 9" do
        expect(subject.send(:image_size,9)).to eq :large
      end

      it "is small when the counter is a not a modulus of 9" do
        expect(subject.send(:image_size,1)).to eq :small
      end
    end

    context "mobile" do

      let(:device) { :mobile }

      it "is mobile regardless of counter" do
        expect(subject.send(:image_size,0)).to eq :mobile
        expect(subject.send(:image_size,1)).to eq :mobile
        expect(subject.send(:image_size,9)).to eq :mobile
      end

    end
    
  end

  context "#image" do
    its(:image) { should eq suite.image }
  end

  context "#title" do
    its(:title) { should eq suite.title }
  end

  context "#permalink" do
    its(:permalink) { should eq suite.permalink }
  end

  context "#target" do
    its(:target) { should eq suite.target }
  end

  context "#id" do
    its(:id) { should eq suite.id }
  end


  context "#suite_tab_presenters" do

    before do
      allow(subject).to receive(:tabs).and_return([tab])
    end

    it "should present its tabs" do
      suite_tab_presenter = double
      expect(Spree::SuiteTabPresenter).to receive(:new).with(tab, view, context.merge(suite: suite, target: target, device: device)).and_return(suite_tab_presenter)
      expect(subject.suite_tab_presenters).to eq [suite_tab_presenter]
    end

  end

  context "#available_stock?" do
    let!(:tab_not_in_stock) { create(:suite_tab, suite: suite, in_stock_cache: false)}

    it "returns false if there is not in_stock_tabs" do
      expect(subject.available_stock?).to eq false
    end

    context "in stock tab" do
      let!(:tab_in_stock) { create(:suite_tab, suite: suite, in_stock_cache: true)}

      it "returns true if there is not in_stock_tabs" do
        expect(subject.available_stock?).to eq true
      end

    end
  end

  context "image methods" do

    let!(:url) { 'the image url'}
    let!(:attachment) { double(url: url) }
    let!(:image) { double(attachment: attachment, alt: 'wooo') }

    before do
      allow(suite).to receive(:image).and_return(image)
    end

    context "#image_alt" do
      its(:image_alt) { should eq 'wooo' }
    end

    describe "#image_url" do
      context "with an image" do
        its(:image_url) { should eq("the image url") }

        context "device is not a mobile" do

          context "with a number divisible by 9" do
            it "attachment should receive a style request for large" do
              expect(attachment).to receive(:url).with(:large)
              subject.image_url(9)
            end
          end

          context "with a number not divisible by 9" do
            it "attachment should receive a style request for large" do
              expect(attachment).to receive(:url).with(:small)
              subject.image_url(8)
            end
          end

        end

        context "device is a mobile" do
          let(:device) { :mobile }

          context "with a number divisible by 9" do
            it "attachment should receive a style request for mobile" do
              expect(attachment).to receive(:url).with(:mobile)
              subject.image_url(9)
            end
          end

          context "with a number not divisible by 9" do
            it "attachment should receive a style request for mobile" do
              expect(attachment).to receive(:url).with(:mobile)
              subject.image_url(8)
            end

          end
        end

      end

      context "without an image" do

        before { allow(suite).to receive(:image).and_return nil }
        its(:image_url) { should eq("/assets/product-group/placeholder-470x600.gif") }

        context "device is a mobile" do
          let(:device) { :mobile }
          its(:image_url) { should eq("/assets/product-group/placeholder-150x192.gif") }
        end

      end
    end

  end

  context "#container_class" do

    context "with a number divisible by 9" do
      it "should return large style" do
        expect(subject.container_class(9)).to eq 'large-8'
      end
    end

    context "with a number not divisible by 9" do
      it "should return small style" do
        expect(subject.container_class(8)).to eq 'large-4'
      end
    end

  end

  context "#title_size_class" do

    it "assigns the correct size (mini) class for a title" do
      suite.title = "Mini Wellington Hat"
      expect(subject.title_size_class).to eq ("mini")
    end

    it "assigns the correct size (small) class for a title" do
      suite.title = "Mini Zion Lion"
      expect(subject.title_size_class).to eq ("small")
    end

    it "assigns the correct size (mini) class for a title" do
      suite.title = "Minis Giles"
      expect(subject.title_size_class).to eq ("medium")
    end

    it "assigns the correct size (mini) class for a title" do
      suite.title = "Mini Hat"
      expect(subject.title_size_class).to eq ("large")
    end

  end

  context "#header_style" do

    context "large top" do
      before { suite.template_id =  Spree::Suite::LARGE_TOP }
      its(:header_style) { should eq 'large top'}
    end

    context "small bottom" do
      before { suite.template_id =  Spree::Suite::SMALL_BOTTOM }
      its(:header_style) { should eq 'small bottom'}
    end

    context "default" do
      before { suite.template_id =  'asdasd' }
      its(:header_style) { should eq 'small bottom'}
    end

    context "inverted" do
      before { suite.inverted = true }
      its(:header_style) { should eq 'small bottom inverted'}
    end


  end

  describe "#link_to_first_tab_in_stock" do
    let!(:suite_tab_presenter_not_in_stock) { double(link_to: 'not_in_stock', in_stock?: false) }
    let!(:suite_tab_presenter_in_stock) { double(link_to: 'in_stock', in_stock?: true) }

    before do
      allow(subject).to receive(:suite_tab_presenters).and_return([
        suite_tab_presenter_not_in_stock,
        suite_tab_presenter_in_stock
      ])
    end

    it "returns link of first tab" do
      expect(subject.link_to_first_tab_in_stock).to eq 'in_stock'
    end
  end

  context "#tab_grid_class" do
    it "assigns correct grid class" do
      expect(subject.tab_grid_class(0)).to eq 'push-3'
      expect(subject.tab_grid_class(1)).to eq 'pull-3'
    end
  end

end
