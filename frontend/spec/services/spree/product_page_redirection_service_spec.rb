require 'spec_helper'

describe Spree::ProductPageRedirectionService, type: :routing do
  subject { Spree::ProductPageRedirectionService }
  let!(:women_target) { create(:target, name: 'Women') }
  let!(:page) { create(:product_page, name: 'Lil Foxy Roxy Women', target: women_target, permalink: 'lil-foxy-roxy-women') }

  before do
  end

  context 'routes' do
    xit "expect to match product page controller" do
      expect(get(spree.product_page_path("lil-foxy-roxy-women"))).
        to route_to(
                    controller: 'spree/product_pages',
                    id: 'lil-foxy-roxy-women'
#                    tab: 'knit-your-own',
#                    rest: '23'
                    )
    end

  end

  context 'kit product' do
    let!(:product) { create(:product, name: 'Lil Foxy Roxy', product_type: create(:product_type_kit)) }
    let!(:tab)   { create(:product_page_tab, product: product, product_page: page) }
    let(:variant) { create(:base_variant, product: product) }
    
    it "with selected variant" do
      o = subject.run(product: product, variant: variant)
      expect(o.result).to eq({
                               url: spree.product_page_path("lil-foxy-roxy-women", :tab => "knit-your-own", variant_id: variant.number),
                               http_code: 301,
                               flash: nil
                             })
    end

    it "with no selected variant" do
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
                               url: spree.product_page_path("lil-foxy-roxy-women", :tab => "knit-your-own"),
                               http_code: 301,
                               flash: nil
                             })
    end
  end

  context 'made-by-the-gang product' do
    let(:product) { create(:product, name: 'Lil Foxy Roxy') }
    let!(:tab)   { create(:product_page_tab, product: product, product_page: page) }
    let(:variant) { create(:base_variant, product: product) }

    it "with selected variant" do
      o = subject.run(product: product, variant: variant)
      expect(o.result).to eq({
                               url: spree.product_page_path("lil-foxy-roxy-women", :tab => "made-by-the-gang", variant_id: variant.number),
                               http_code: 301,
                               flash: nil
                             })
    end

    it "with no selected variant" do
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
        url: spree.product_page_path("lil-foxy-roxy-women", :tab => "made-by-the-gang"),
                               http_code: 301,
                               flash: nil
                             })
    end    
  end

  context 'supply product' do
    let(:product) { create(:product, name: 'Lil Foxy Roxy Pattern') }
    let(:variant) { create(:base_variant, product: product) }
    let(:page)    { create(:product_page, name: 'Patterns', target: nil, permalink: 'pattern') }
    let!(:tab)   { create(:product_page_tab, product: product, product_page: page) }

    it "with selected variant" do
      o = subject.run(product: product, variant: variant)
      expect(o.result).to eq({
                               url: spree.product_page_path("pattern", :tab => "made-by-the-gang", variant_id: variant.number),
                               http_code: 301,
                               flash: nil
                             })
    end

    it "with no selected variant" do
      o = subject.run(product: product, variant: nil)
      expect(o.result).to eq({
                               url: spree.product_page_path("pattern", :tab => "made-by-the-gang"),
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
