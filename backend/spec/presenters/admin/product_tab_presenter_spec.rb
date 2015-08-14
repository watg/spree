require 'spec_helper'

module Admin
  describe ProductTabPresenter do
    subject       { described_class.new(product) }
    let(:product) { create(:product) }
    let(:part)    { create(:product) }

    describe '#parts?' do
      context 'kit' do
        before { product.product_type.name = 'kit' }
        it     { expect(subject.parts?).to be_truthy }
      end

      context 'ready to wear' do
        before { product.product_type.name = 'normal' }
        it     { expect(subject.parts?).to be_truthy }
      end
    end
  end
end
