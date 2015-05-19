require 'spec_helper'

describe CreateVideoService do
  let(:params) { { title: title, url: url } }
  let(:title)  { %[New Vid]}
  let(:url)    { %[https://youtube.com/watch?v=111] }

  context 'valid' do 
    before         { described_class.run(params) }
    let(:actual)   { Video.first.embed }

    context 'youtube' do
      let(:url)   { %[https://www.youtube.com/watch?v=Fh5x40Y2Bd0] }
      let(:embed) { create_youtube_iframe('https://www.youtube.com/embed/Fh5x40Y2Bd0') }

      it { expect(actual).to eq embed }
    end

    context 'vimeo url' do
      let(:url)   { %[https://vimeo.com/118077207] }
      let(:embed) { create_vimeo_iframe("https://player.vimeo.com/video/118077207") }

      it { expect(actual).to eq embed }
    end
  end

  context 'invalid' do 
    subject { described_class.run(new_params) }

    context 'not youtube or vimeo url'  do 
      let(:new_params) { params.merge(url: %[https://whatever.com]) }
      it { is_expected.to_not be_valid  }
    end

    context 'duplicate title' do
      let(:new_params) { params.merge(url: %[https://vimeo.com/new] ) }
      let(:errors)     { subject.errors.messages }
      before { Video.create(params) }
      it     { expect(errors).to eq({ :title=>['already exists'] }) }
    end

    context 'duplicate url' do
      let(:new_params) { params.merge(title:  %[new version])  }
      let(:errors)     { subject.errors.messages }
      before { Video.create(params) }
      it     { expect(errors).to eq({ :url=>['already exists'] }) }
    end
  end

  def create_youtube_iframe(uri, opts = 'allowfullscreen')
    create_iframe(uri, opts)
  end

  def create_vimeo_iframe(uri, opts = 'webkitallowfullscreen mozallowfullscreen allowfullscreen')
    create_iframe(uri, opts)
  end

  def create_iframe(uri, opts)
    %Q[<iframe src="#{uri}" width="100%" height="315" frameborder="0" #{opts}></iframe>]
  end
end
