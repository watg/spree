require 'spec_helper'

describe CreateVideoService do
  let(:video) { Video.new(embed: url ) }

  context 'youtube' do
    let(:url)	{ %[https://www.youtube.com/watch?v=Fh5x40Y2Bd0] }
    let(:embed) { create_youtube_iframe('https://www.youtube.com/embed/Fh5x40Y2Bd0') }

    it 'creates youtube embed' do
      described_class.new(video).run
      expect(Video.first.embed).to eq embed
    end
  end

  context 'vimeo url' do
    let(:url) { %[https://vimeo.com/118077207] }
    let(:embed) { create_vimeo_iframe("https://player.vimeo.com/video/118077207") }

    it 'creates vimeo embed' do
      described_class.new(video).run
      expect(Video.first.embed).to eq embed
    end
  end

  def create_youtube_iframe(uri, opts = "allowfullscreen")
    create_iframe(uri, opts)
  end

  def create_vimeo_iframe(uri, opts = "webkitallowfullscreen mozallowfullscreen allowfullscreen")
    create_iframe(uri, opts)
  end

  def create_iframe(uri, opts)
    %Q[<iframe src="#{uri}" width="460" height="315" frameborder="0" #{opts}></iframe>]
  end
end
