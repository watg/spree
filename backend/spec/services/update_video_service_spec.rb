require 'spec_helper'

describe UpdateVideoService do 
  let(:params) { {title: 'Crochet baby!', url: 'https://vimeo.com/112213893'} }
  
  context 'same params' do 
    let(:embed) { double(embed_code: '<iframe></iframe>') }
    let(:video) { Video.first }

    before do 
      CreateVideoService.run(params) 
      allow(Embed).to receive(:build).with(params[:url]).and_return(embed)
      described_class.run(params.merge(id: Video.first.id))
    end

    it { expect(Video.count).to eq 1 }
    it { expect(video.title).to eq params[:title] }
    it { expect(video.embed).to eq embed.embed_code }
  end

  context 'new params' do 
    let(:embed)      { double(embed_code: '<iframe></iframe>') }
    let(:new_params) { params.merge(url: 'https://vimeo.com/30821530', id: Video.first.id) }
    let(:video)      { Video.first }

    before do 
      CreateVideoService.run(params) 
      allow(Embed).to receive(:build).with(new_params[:url]).and_return(embed)
      described_class.run(new_params)
    end

    it { expect(Video.count).to eq 1 }
    it { expect(video.title).to eq params[:title] }
    it { expect(video.embed).to eq embed.embed_code }
  end

  context 'duplicate title' do 
    before do
      CreateVideoService.run(params)
      CreateVideoService.run({title: 'Knit me', url: 'https://vimeo.com/30821530'})
    end

    let(:outcome) { described_class.run(params.merge(url: 'https://vimeo.com/30821530', id: Video.last.id)) }
    let(:errors)  { outcome.errors.messages }

    it { expect(errors).to eq({:title=>["already exists"]}) }
  end

  context 'title missing' do 
    before        { CreateVideoService.run(params) }
    let(:outcome) { described_class.run({title: '', url: 'https://vimeo.com/30821530', id: Video.last.id }) }
    let(:errors)  { outcome.errors.messages }

    it { expect(errors).to eq({:title=>["can't be blank"]}) }
  end

  context 'url missing' do 
    before        { CreateVideoService.run(params) }
    let(:outcome) { described_class.run({title: 'Crochet baby!', url: '', id: Video.last.id }) }
    let(:errors)  { outcome.errors.messages }

    it { expect(errors).to eq({:url=>["can't be blank"]}) }
  end

  context 'not youtube or vimeo url'  do 
    before        { CreateVideoService.run(params) }
    let(:outcome) { described_class.run(params.merge(url: %[https://whatever.com], id: Video.last.id)) }
    let(:errors)  { outcome.errors.messages } 

    it { expect(errors).to eq({:url=>["youtube or vimeo urls only"]}) }
  end
end