require 'spec_helper'

describe DestroyVideoService do 
  let!(:vid) { Video.create(title: 'T', url: %[https://vimeo.com/112213893]) }

  it 'deletes video' do 
    described_class.run({ id: vid.id } )
    expect(Video.count).to eq 0
  end
end