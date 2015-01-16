require 'spec_helper'

describe Spree::OrdersHelper do
  subject     { Object.extend(Spree::OrdersHelper) }
  let(:linkshare_config) { URI(LinkShare.base_url) }
  let(:order) { decorated_order = double(linkshare_params: {a: ["foo"], b: ["bar"]}) ; double(decorate: decorated_order) }

  it "builds linkshare_url" do
    uri = URI(subject.linkshare_url(order))
    expect(uri.scheme).to eq linkshare_config.scheme
    expect(uri.host).to   eq linkshare_config.host
    expect(uri.path).to   eq linkshare_config.path
    expect(uri.query).to  eq "a=foo&b=bar"
  end

  it "truncates HTML correctly in product description" do
    product = double(:description => "<strong>" + ("a" * 95) + "</strong> This content is invisible.")
    expected = "<strong>" + ("a" * 95) + "</strong>..."
    expect(truncated_product_description(product)).to eq(expected)
  end
end
