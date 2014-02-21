require 'spec_helper'

describe Spree::VariantDecorator do
  let(:variant) { create(:variant) }
  let(:currency) { "USD" }
  let(:target) { create(:target) }

  subject { variant.decorate( context: { target: target, current_currency: currency } ) }

  its(:id) { should eq(variant.id) }
  its(:name) { should eq(variant.name) }
  its(:product) { should eq(variant.product) }
  its(:gang_member) { should eq(variant.product.gang_member) }

  context "with no images" do
    its(:first_image) { should be_nil }

    it "returns the oops image url" do
      expect(subject.first_image_url(:product)).to eq("/assets/product-group/placeholder-470x600.gif")
    end
  end

  context "images" do
    let(:images) { create_list(:image, 2) }

    it "returns first image with target" do
      allow(variant).to receive(:images_for).with(target).and_return(images)
      subject.first_image.should eq(images.sort_by(&:position).first)
    end

    it "returns first image without target" do
      allow(variant).to receive(:images).and_return(images)
      subject = variant.decorate( context: { current_currency: currency } )
      subject.first_image.should eq(images.sort_by(&:position).first)
    end
  end

  context "with tags" do
    let(:tags) { create_list(:tag, 2) }

    before :each do
      variant.tags = tags
    end

    its(:tag_names) { should match_array(tags.map(&:value)) }
  end


  its(:price) { should eq(variant.price_normal_in(currency)) }
  its(:in_sale?) { should be_false }

  context "with sale prices" do
    let(:variant) { create(:variant_in_sale) }

    its(:sale_price) { should eq(variant.price_normal_sale_in(currency)) }
    its(:in_sale?) { should be_true }
  end

  context "master variant" do
    before do
      variant.update_attributes(is_master: true)
    end

    it { should be_is_master }
  end

  context "non-master variant" do
    before do
      variant.update_attributes(is_master: false)
    end

    it { should_not be_is_master }
  end

  its(:option_values) { should eq(variant.option_values) }

end
