require 'spec_helper'

describe CreateProductVideosService do 
  let(:product) { create(:product) }
  let(:video)   { Video.create(title: 'T', url: %[https://vimeo.com/112213893]) }
  let(:video_2) { Video.create(title: 'X', url: %[https://vimeo.com/55555555]) }
  let(:videos)  { [video, video_2] }
  let(:params)  { { "videos" => videos.map(&:id), "id" => product.id } }

  it 'assigns videos to product' do 
    described_class.run(params)
    expect(product.videos).to eq videos
  end

  context 'no videos selected' do 
    let(:params)  { { "id" => product.id } }
    before        { product.videos = videos }

    it 'removes videoes' do 
      described_class.run(params) 
      expect(Spree::Product.find(product.id).videos).to eq [] 
    end
  end
end