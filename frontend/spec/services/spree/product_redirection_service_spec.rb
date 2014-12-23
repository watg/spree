require 'spec_helper'

describe Spree::ProductRedirectionService, type: :routing do
  subject { Spree::ProductRedirectionService }
  let!(:women_target) { create(:target, name: 'Women') }
  let!(:page) { create(:suite, name: 'Lil Foxy Roxy Women', target: women_target, permalink: 'lil-foxy-roxy-women') }

  before do
  end

  context 'kit product' do
    let!(:product) { create(:product, name: 'Lil Foxy Roxy', product_type: create(:product_type_kit)) }
    let!(:tab)   { create(:suite_tab, product: product, suite: page) }
    let(:variant) { create(:base_variant, product: product) }
    
    it "with selected variant" do
      o = subject.run(product: product, variant: variant)
      expect(o.result).to eq({
                               url: spree.suite_path("lil-foxy-roxy-women", :tab => "knit-your-own", variant_id: variant.number),
                               http_code: 301,
                               flash: nil
                             })
    end

    it "with no selected variant" do
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
                               url: spree.suite_path("lil-foxy-roxy-women", :tab => "knit-your-own"),
                               http_code: 301,
                               flash: nil
                             })
    end
  end

  context 'made-by-the-gang product' do
    let(:product) { create(:product, name: 'Lil Foxy Roxy') }
    let!(:tab)   { create(:suite_tab, product: product, suite: page) }
    let(:variant) { create(:base_variant, product: product) }

    it "with selected variant" do
      o = subject.run(product: product, variant: variant)
      expect(o.result).to eq({
                               url: spree.suite_path("lil-foxy-roxy-women", :tab => "made-by-the-gang", variant_id: variant.number),
                               http_code: 301,
                               flash: nil
                             })
    end

    it "with no selected variant" do
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
        url: spree.suite_path("lil-foxy-roxy-women", :tab => "made-by-the-gang"),
                               http_code: 301,
                               flash: nil
                             })
    end    
  end

  context 'supply product' do
    let(:product) { create(:product, name: 'Lil Foxy Roxy Pattern') }
    let(:variant) { create(:base_variant, product: product) }
    let(:page)    { create(:suite, name: 'Patterns', target: nil, permalink: 'pattern') }
    let!(:tab)   { create(:suite_tab, product: product, suite: page) }

    it "with selected variant" do
      o = subject.run(product: product, variant: variant)
      expect(o.result).to eq({
                               url: spree.suite_path("pattern", :tab => "made-by-the-gang", variant_id: variant.number),
                               http_code: 301,
                               flash: nil
                             })
    end

    it "with no selected variant" do
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
                               url: spree.suite_path("pattern", :tab => "made-by-the-gang"),
                               http_code: 301,
                               flash: nil
                             })
    end
  end


  context 'Exceptions Handling' do
    it 'no product found' do
      o = subject.run(product: nil, variant: nil)
      expect(o.result).to eq({
                               url: "/",
                               http_code: 302,
                               flash: 'Item not found'
                             })
    end

    it 'no product page found' do
      product = create(:product)
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
                               url: "/",
                               http_code: 302,
                               flash: 'Page not found'
                             })
    end
  end
end
