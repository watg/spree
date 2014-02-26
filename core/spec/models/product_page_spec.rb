require 'spec_helper'

describe Spree::ProductPage do
  let(:product_group) { create(:product_group) }
  subject { create(:product_page, name: ' Zion liOn haT  ', title: 'zion lion', permalink: nil) }

  before do
    subject.product_groups << product_group
  end

  its(:title) { should eql('zion lion') }

  it "should not allow unnamed group to be saved" do
    subject.name = nil
    expect(subject).to be_invalid
  end

  context "permalink" do
    its(:permalink) { should eql('zion-lion-hat') }

    it "can change permalink" do
      subject.permalink = 'anything-unique'
      expect(subject.save).to be_true
    end

    it "does not include illegal charecters" do
      product_page = create(:product_page, permalink: "wacky,' day")
      expect(product_page.permalink).to eq "wacky-day"
    end
  end

  it "returns desired tab" do
    expect(subject.tab(:made_by_the_gang).tab_type).to eql("made_by_the_gang")
  end

  it "creates its tabs automatically" do
    tabs = subject.tabs
    expect(tabs.count).to eq(2)
    expect(tabs.first.tab_type).to eq("made_by_the_gang")
    expect(tabs.second.tab_type).to eq("knit_your_own")
  end

  describe "class methods" do
    let(:variants_in_stock)    { create_list(:variant_with_stock_items, 2) }
    let(:variant_out_of_stock) { create(:base_variant) }

    before do
      (variants_in_stock + [variant_out_of_stock]).each do |v|
        create(:product_page_variant, product_page: subject, variant: v)
      end
    end

    it "checks stock level" do
      expect(subject.displayed_variants_in_stock).to match_array(variants_in_stock)
    end
  end

  context "validation" do
    it "name is unique" do
      same_name_pg = build(:product_page, name: subject.name)
      expect(same_name_pg).to be_invalid
    end

    it "title is required" do
      product_page = build(:product_page)
      expect(product_page).to be_valid
      product_page.title = ""
      expect(product_page).to be_invalid
    end
  end

  context "kit" do
    let(:kit) { create(:product, product_group: product_group, product_type: "kit") }

    it "creates a product_group if it does not exist when kit added" do
      subject.product_groups = []
      subject.kit = kit
      subject.save
      expect(subject.product_groups).to eq([kit.product_group])
    end

    it "does not creates a product_group if it does exist when kit added" do
      subject.product_groups = [kit.product_group]
      subject.kit = kit
      expect(subject.product_groups).to eq([kit.product_group])
    end

  end

  describe "#available_variants" do
    let(:kit) { create(:product, product_group: product_group, product_type: "kit") }
    let(:kit_variants) { create_list(:variant, 2, product: kit) }

    let(:made_by_the_gang_product) { create(:product, product_group: product_group, product_type: "made_by_the_gang") }
    let(:made_by_the_gang_targeted_variants) { create_list(:variant, 3, product: made_by_the_gang_product) }

    let(:other_target) { create(:target) }
    let(:made_by_the_gang_other_target_variants) { create_list(:variant, 2, product: made_by_the_gang_product) }

    let(:displayed_variants) { [made_by_the_gang_targeted_variants[2]] }

    before :each do
      kit_variants.each { |v| v.targets << subject.target }
      made_by_the_gang_targeted_variants.each { |v| v.targets << subject.target }
      made_by_the_gang_other_target_variants.each { |v| v.targets << other_target }
      subject.displayed_variants = displayed_variants
    end

    it "returns available variants with the same target, excluding kit products" do
      expect(subject.available_variants).to eq(made_by_the_gang_targeted_variants[0..1])
    end

    context "without a product page target" do
      before do
        subject.update_attributes(target: nil)
      end

      it "returns available variants for all targets" do
        variants = made_by_the_gang_targeted_variants +
          made_by_the_gang_other_target_variants -
          displayed_variants
        expect(subject.available_variants).to eq(variants)
      end
    end
  end

  describe "variant prices" do
    describe "made by the gang" do

      let(:product1) { create(:product_with_prices, usd_price: 29.99, gbp_price: 8.00) }
      let(:product2) { create(:product_with_prices, usd_price: 30.00, gbp_price: 7.00) }
      let(:product3) { create(:product_with_stock_and_prices, usd_price: 33.00, gbp_price: 7.50) }
      let(:product4) { create(:product_with_stock_and_prices, usd_price: 33.01, gbp_price: 7.49) }
      let(:product5) { create(:product_with_stock_and_prices, usd_price: 33.01, gbp_price: 7.49) }

      before do
        sale_price1 = create(:price, sale: true, amount: 1.00, currency: 'GBP', variant: product4.master ) 
        sale_price2 = create(:price, sale: true, amount: 2.00, currency: 'GBP', variant: product5.master )
        product5.master.update_attributes(in_sale: true)

        [product1,product2,product3,product4,product5].each do |product|
          subject.displayed_variants << product.master 
        end
      end

      it "return the lowest normal price for USD" do
        expect(subject.lowest_normal_price("USD", :made_by_the_gang ).amount.to_s).to eq product3.master.price_normal_in('USD').amount.to_s
      end

      it "return the lowest normal price for GBP" do
        expect(subject.lowest_normal_price("GBP", :made_by_the_gang ).amount).to eq product4.master.price_normal_in('GBP').amount
      end

      it "return the highest normal price for USD" do
        expect(subject.highest_normal_price("USD", :made_by_the_gang ).amount).to eq product4.master.price_normal_in('USD').amount
      end

      it "return the highest normal price for GBP" do
        expect(subject.highest_normal_price("GBP", :made_by_the_gang ).amount).to eq product3.master.price_normal_in('GBP').amount
      end

      it "return the lowest sale price for GBP" do
        expect(subject.lowest_sale_price("GBP", :made_by_the_gang ).amount).to eq product5.master.price_normal_sale_in('GBP').amount
      end

      it "return nil for a currency that has no valid sale items" do
        expect(subject.lowest_sale_price("USD", :made_by_the_gang )).to be_nil
      end

    end

    describe "knit your own" do
      it "for knit your own" do
        product = create(:product, product_type: :kit, product_group: product_group)
        subject.kit = product
        variant1 = create(:variant, price: 17.99, currency: "USD", product: product, in_stock_cache: true)
        variant2 = create(:variant, price: 1.99, currency: "USD", product: product, in_stock_cache: false)
        variant3 = create(:variant, price: 18.99, currency: "USD", product: product, in_stock_cache: true)
        variant4 = create(:variant, price: 16.99, currency: "GBP", product: product, in_stock_cache: true)

        expect(subject.lowest_normal_price("USD", :knit_your_own ).variant).to eq variant1
      end
    end
  end


  describe "made_by_the_gang details" do
    let!(:tab) { create(:product_page_tab, product_page: subject, tab_type: :made_by_the_gang, background_color_code: "123456") }

    before :each do
      allow(subject).to receive(:tab).with(:made_by_the_gang).and_return(tab)
    end

  end

  describe "kit details" do
    let!(:tab) { create(:product_page_tab, product_page: subject, tab_type: :knit_your_own, background_color_code: "123456") }

    before :each do
      allow(subject).to receive(:tab).with(:knit_your_own).and_return(tab)
    end

  end

  describe "#available_tags" do
    let(:tags) { 3.times.map { create(:tag) } }
    let(:product) { create(:product_with_variants) }

    before :each do
      subject.product_groups << product.product_group
      product.variants.first.tags = tags[0,2]
      product.variants.last.tags = tags[1,2]
    end

    it "should return the unique'd tags from all variants" do
      expect(subject.available_tags.sort).to eq(tags.sort)
    end
  end

  describe "#tag_names" do
    let(:tags) { 3.times.map { create(:tag) } }
    let(:product) { create(:product_with_variants) }

    before :each do
      subject.product_groups << product.product_group
      product.variants.first.tags = tags[0,2]
      product.variants.last.tags = tags[1,2]
      subject.tags = tags[0,2]
    end

    it "should return the names of the tags enabled for this product group" do
      expect(subject.tag_names).to eq(tags[0,2].map(&:value))
    end

    describe "#visible_tag_names" do
      before do
        create(:product_page_variant, product_page: subject,  variant: product.variants.first)
      end

      it "should return the names of visible tags" do
        expect(subject.visible_tag_names).to match_array(tags[0,2].map(&:value))
      end
    end

  end

  describe "all_variants" do
    it "returns all_variants_or_master from all products" do

      product1 = create(:product, :product_type => :product, :product_group => product_group)
      variant1 = create(:base_variant, :product => product1 )
      variant2 = create(:base_variant, :product => product1 )
      product2 = create(:product, :product_type => :product, :product_group => product_group)
      product_page = create(:product_page, :product_groups => [product_group])

      expect(product_page.all_variants.size).to eq 3
    end

    it "does not return a virtual_product" do
      virtual_product = create(:product, :product_type => :virtual_product, :product_group => product_group)
      product_page = create(:product_page, :product_groups => [product_group])

      expect(product_page.all_variants.size).to eq 0
    end
  end

  describe "touching" do
    let!(:index_page_item) { create(:index_page_item, product_page: subject, updated_at: 1.month.ago) }

    before { Timecop.freeze }
    after { Timecop.return }

    it "touches any index page items after a touch" do
      subject.reload # reload to pick up the product_page has_many
      subject.touch
      expect(index_page_item.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

    it "touches any index page items after a save" do
      subject.reload # reload to pick up the product_page has_many
      subject.title = 'ffff'
      subject.save
      expect(index_page_item.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end
  end
end
