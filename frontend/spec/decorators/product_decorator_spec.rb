require "spec_helper"

describe Spree::ProductDecorator do
  let(:product) { create(:base_product) }
  let(:currency) { "USD" }
  let(:target) { create(:target) }

  subject { product.decorate(context: { target: target, current_currency: currency }) }

  context "price" do
    it "returns the price_normal_in for a product" do
      expect(subject.price).to eq(product.price_normal_in("USD"))
    end
  end

  context "images" do
    let(:images) { create_list(:image, 2) }

    it "returns first image with target" do
      allow(product).to receive(:images_for).with(target).and_return(images)
      expect(subject.first_image).to eq(images.sort_by(&:position).first)
    end

    it "returns first image without target" do
      allow(product).to receive(:variant_images).and_return(images)
      subject = product.decorate(context: { current_currency: currency })
      expect(subject.first_image).to eq(images.sort_by(&:position).first)
    end
  end

  context "description" do
    it "returns targeted description" do
      allow(product).to receive(:description_for).with(target).and_return("Simple, but cool & targeted description")
      expect(subject.description).to eq("Simple, but cool & targeted description")
    end

    it "returns basic description with no target" do
      allow(product).to receive(:description_for).and_return("Very berry basic description")
      expect(subject.description).to eq("Very berry basic description")
    end
  end
end
