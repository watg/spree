require 'spec_helper'

module Admin
  describe VideosController, type: :controller do 
    let(:attributes) { { title: title, url: url } }
    let(:title)      { 'Stitched Up Video' }
    let(:url)        { 'https://vimeo.com/112213893' } 

    describe '#create' do 
      context 'valid attributes' do 
        it 'creates new videos' do 
          spree_post :create, video: attributes
          expect(Video.count).to eq 1
          expect(Video.all.first.title).to eq 'Stitched Up Video'
          expect(response).to redirect_to '/admin/videos'
          expect(flash[:success]).to eq 'Video created'
        end
      end

      context 'title missing' do 
        let(:title) { ' ' }

        it 'notifies user' do 
          spree_post :create, video: attributes
          expect(Video.count).to eq 0
          expect(flash[:error]).to eq 'Could not create video'
        end
      end

      context 'embed missing' do 
        let(:embed) { ' ' }

        it 'notifies user' do 
          spree_post :create, video: { title: 'Stitched Up Video', embed: '' }
          expect(Video.count).to eq 0
          expect(flash[:error]).to eq 'Could not create video'
        end
      end

      context 'mass assignment' do 
        let(:bad_attributes) { attributes.merge(statement: 'kill all') }
        let(:video)          { double(save: nil, update: nil) }

        it 'only passes valid attributes' do 
          expect(Video).to receive(:new).with(attributes).and_return(video)
          spree_post :create, video: bad_attributes
        end
      end
    end

    describe '#edit' do 
      before { spree_post :create, video: attributes }

      context 'valid attributes' do 
        let(:valid_attr) { { id: Video.first.id, title: 'New', embed: embed } }

        it 'updates video' do 
          spree_post :update, video: valid_attr
          expect(Video.count).to eq 1
          expect(Video.first.title).to eq 'New'
          expect(response).to redirect_to '/admin/videos'
          expect(flash[:success]).to eq 'Video created'
        end
      end

      context 'invalid attributes' do 
        let(:invalid_attr) { { id: Video.first.id, title: ' ', embed: embed } }

        it 'notifies user' do 
          spree_post :update, video: invalid_attr
          expect(Video.count).to eq 1
          expect(flash[:error]).to eq 'Could not create video'
        end
      end
    end

    describe '#destroy' do 
      before { spree_post :create, video: attributes }

      it 'deletes video' do 
        spree_post :destroy, id: Video.first.id 
        expect(Video.count).to eq 0
        expect(response).to redirect_to '/admin/videos'
        expect(flash[:success]).to eq 'Video deleted'
      end
    end
  end
end