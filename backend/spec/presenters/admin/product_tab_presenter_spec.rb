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

        context 'feature flag set' do
          before { expect(ENV).to receive(:[]).with('PRODUCT_PARTS').and_return(true) }
          it     { expect(subject.parts?).to be_truthy }
        end

        context 'no feature flag' do
          it { expect(subject.parts?).to be_falsey}
        end
      end
    end

    describe '#static_parts?' do
      let(:product)      { double(static_assemblies_parts: [static_part]) }
      let(:static_part)  { double }

      it { expect(subject.static_parts?).to be_truthy }
    end
  end
end
