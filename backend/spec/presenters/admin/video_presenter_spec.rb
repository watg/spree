require 'spec_helper'

module Admin
  describe VideoPresenter do 
    subject       { described_class.new(video, product) }
    let(:video)   { Video.create(title: 'T', url: %[https://vimeo.com/112213893]) }
    let(:product) { create(:product) }

    describe '#status' do 
      context 'video belongs to product' do 
        before { product.videos << video }
        it     { expect(subject.status).to eq 'checked' }
      end

      context 'video does not belong to product' do 
        it {  expect(subject.status).to be_falsey }
      end
    end
  end
end