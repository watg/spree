require "spec_helper"

module Misc
  describe UrlSlicer do
    let(:url) { "/suites?&another-param=value&keywords=wool+pattern&page=2&utf8=%E2%9C%93" }

    subject { described_class.run(url: url) }

    it "strips params anything apart from `keywords` and `page`" do
      expect(subject.result).to eq "/suites?keywords=wool+pattern&page=2"
    end
  end
end
