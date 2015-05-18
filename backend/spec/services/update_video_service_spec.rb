require 'spec_helper'

describe UpdateVideoService do 
  let(:params) { {title: 'Crochet baby!', embed: 'https://vimeo.com/112213893'} }
  
  context 'same params' do 
    before { CreateVideoService.run(params) }

    it 'updates video' do 
      UpdateVideoService.run(params.merge(id: Video.first.id))
      expect(Video.count).to eq 1
      expect(Video.first.title).to eq params[:title]
      expect(Video.first.embed).to eq %[<iframe src=\"https://player.vimeo.com/video/112213893\" width=\"100%\" height=\"315\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>]
    end
  end

  context 'new params' do 
    before { CreateVideoService.run(params) }

    it 'amends video' do 
      UpdateVideoService.run(params.merge(embed: 'https://vimeo.com/30821530', id: Video.first.id))
      expect(Video.count).to eq 1
      expect(Video.first.title).to eq params[:title]
      expect(Video.first.embed).to eq %[<iframe src=\"https://player.vimeo.com/video/30821530\" width=\"100%\" height=\"315\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>]
    end
  end

  context 'duplicate title' do 
    before do
      CreateVideoService.run(params)
      CreateVideoService.run({title: 'Knit me', embed: 'https://vimeo.com/30821530'})
    end

    let(:outcome) { UpdateVideoService.run(params.merge(embed: 'https://vimeo.com/30821530', id: Video.last.id)) }
    let(:errors)  { outcome.errors.messages }

    it { expect(errors).to eq({:title=>["already exists"]}) }
  end

  context 'title missing' do 
    before        { CreateVideoService.run(params) }
    let(:outcome) { UpdateVideoService.run({title: '', embed: 'https://vimeo.com/30821530', id: Video.last.id }) }
    let(:errors)  { outcome.errors.messages }

    it { expect(errors).to eq({:title=>["can't be blank"]}) }
  end

  context 'embed missing' do 
    before        { CreateVideoService.run(params) }
    let(:outcome) { UpdateVideoService.run({title: 'Crochet baby!', embed: '', id: Video.last.id }) }
    let(:errors)  { outcome.errors.messages }

    it { expect(errors).to eq({:embed=>["can't be blank"]}) }
  end

  context 'not youtube or vimeo url'  do 
    before        { CreateVideoService.run(params) }
    let(:outcome) { described_class.run(params.merge(embed: %[https://whatever.com], id: Video.last.id)) }
    let(:errors)  { outcome.errors.messages } 

    it { expect(errors).to eq({:embed=>["youtube or vimeo urls only"]}) }
  end
end