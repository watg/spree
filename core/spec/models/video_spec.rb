require 'spec_helper'

describe Video do
  it{ is_expected.to respond_to(:title) }
  it{ is_expected.to respond_to(:embed) }

  describe 'products' do
    let(:video)     { Video.new }
    let(:product)   { build(:product) }
    let(:product_2) { build(:product) }
    let(:products)  { [product, product_2]}

    context 'many' do
      before { video.products = products }
      it     { expect(video.products).to eq products }
    end
  end
end
