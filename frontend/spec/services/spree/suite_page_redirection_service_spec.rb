require 'spec_helper'

describe Spree::SuitePageRedirectionService do

  subject { Spree::SuitePageRedirectionService }

  let(:target) { mock_model(Spree::Target) }

  let(:permalink) { 'lil-foxy-roxy-women' }

  describe "#run" do

    context "when a matching suite is found" do
      let!(:suite) { create(:suite, name: 'Lil Foxy Roxy Women', target: target, permalink: 'lil-foxy-roxy-women') }

      it "returns a suite url and a permanent redirect code" do
        outcome = subject.run(permalink: permalink, params: { tab:'knit-your-own'} ).result

        expect(outcome).to be_kind_of Hash
        expect(outcome[:url]).to eq spree.suite_path(suite, tab: 'knit-your-own')
        expect(outcome[:http_code]).to eq :moved_permanently
      end

      context "Arbitary params are passed on e.g. for referalls" do

        it "returns to root_url with a temporary redirect" do
          outcome = subject.run(permalink: permalink, params: { tab: 'knit-your-own', foo: 'bar'} ).result

          expect(outcome).to be_kind_of Hash
          expect(outcome[:url]).to eq spree.suite_path(suite, tab: 'knit-your-own', foo: 'bar')
          expect(outcome[:http_code]).to eq :moved_permanently
        end
      end

    end

    context "when a matching suite is not found" do

      it "returns to root_url with a temporary redirect" do
        outcome = subject.run(permalink: permalink, params: { tab:'knit-your-own'} ).result

        expect(outcome).to be_kind_of Hash
        expect(outcome[:url]).to eq spree.root_path
        expect(outcome[:http_code]).to eq :temporary_redirect
      end
    end

  end

end
