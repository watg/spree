require 'spec_helper'

describe Spree::OrdersHelper do
  subject     { Object.extend(Spree::OrdersHelper) }

  it "truncates HTML correctly in product description" do
    product = double(:description => "<strong>" + ("a" * 95) + "</strong> This content is invisible.")
    expected = "<strong>" + ("a" * 95) + "</strong>..."
    expect(truncated_product_description(product)).to eq(expected)
  end

  describe "referring_page" do
    before do
      request = double('request', referrer: 'where_i_came_from' )
      allow(subject).to receive(:request).and_return request
    end

    it "redirects back to the referring page" do
      expect(subject.referring_page).to eq 'where_i_came_from'
    end

    context "referrer is nil" do

      before do
        request = double('request', referrer: nil )
        allow(subject).to receive(:request).and_return request
        allow(subject).to receive(:root_path).and_return 'root_path'
      end

      it "redirects back to root" do
        expect(subject.referring_page).to eq 'root_path'
      end

    end
  end

end
