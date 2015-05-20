require 'spec_helper'

module Admin
  module Products
    describe VideosController, type: :controller do 
      describe '#index' do 
        let(:product) { double }
        let(:klass)   { Spree::Product }

        it 'calls product' do 
          expect(klass).to receive(:find_by_slug).with('top-hat').and_return(product)
          spree_post :index, { product_id: 'top-hat' }
        end

        it 'calls video' do 
          expect(Video).to receive(:all)
          spree_post :index, { product_id: 'top-hat' }
        end
      end

      describe '#create' do 
        let(:result)  { double(slug: 'top-hat') }
        let(:product) { create(:product) }
        let(:params)  { { "videos" => %w[1 2], "id" => product.id.to_s } }
        let(:service) { double(valid?: true, result: product) }
        let(:klass)   { CreateProductVideosService }
        
        before { allow(klass).to receive(:run).with(params).and_return(service) }
  
        it 'redirects to index' do 
          spree_post :create, { product: params }
          expect(response).to redirect_to "/admin/products/#{product.slug}/edit"
        end

        it 'notifies user' do 
          spree_post :create, { product: params }
          expect(flash[:success]).to eq 'Product updated'
        end
      end
    end
  end
end