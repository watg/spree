require 'spec_helper'

describe Spree::ProductDecorator do
  let(:product) { create(:base_product) }
  let(:currency) { "USD" }
  let(:target) { create(:target) }

  subject { product.decorate( context: { target: target, current_currency: currency } ) }

  context "images" do
    let(:images) { create_list(:image, 2) }

    it "returns first image with target" do
      allow(product).to receive(:images_for).with(target).and_return(images)
      subject.first_image.should eq(images.sort_by(&:position).first)
    end

    it "returns first image without target" do
      allow(product).to receive(:variant_images).and_return(images)
      subject = product.decorate( context: { current_currency: currency } )
      subject.first_image.should eq(images.sort_by(&:position).first)
    end
  end

  context "description" do

    it "returns targeted description" do
      allow(product).to receive(:description_for).with(target).and_return("Simple, but cool & targeted description")
      subject.description.should eq("Simple, but cool & targeted description")
    end

    it "returns basic description with no target" do
      allow(product).to receive(:description_for).and_return("Very berry basic description")
      subject.description.should eq("Very berry basic description")
    end

  end

end
