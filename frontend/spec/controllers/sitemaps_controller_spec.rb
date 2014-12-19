require 'spec_helper'

describe SitemapsController do

  before do 
    allow_any_instance_of(SitemapsController).to receive(:s3_bucket).and_return('foobar')
  end

  it "returns the location of the sitemap" do
    spree_get :show
    expect(response).to redirect_to("http://foobar.s3.amazonaws.com/sitemaps/sitemap.xml.gz")
  end

end
