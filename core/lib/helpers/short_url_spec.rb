require 'spec_helper'

require 'helpers/short_url'
include Helpers::ShortUrl

describe Helpers::ShortUrl do

  it "initializes short_url with correct host" do
    mock = mock_model(Shortener::ShortenedUrl, unique_key: 'jmfv0')
    expect(Shortener::ShortenedUrl).to receive(:generate).with('http://foo.bar/1235',nil).and_return(mock)
    expect(shorten('http://foo.bar/1235')).to eq 'http://www.example.com/s/jmfv0'
  end

end