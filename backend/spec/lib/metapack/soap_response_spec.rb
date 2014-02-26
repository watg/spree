require 'spec_helper'

describe Metapack::SoapResponse do
  describe "#success?" do
    context "when the http response was successful" do
      subject { Metapack::SoapResponse.new(Net::HTTPResponse.new(1.0, '200', '')) }
      its(:success?) { should be_true }
    end

    context "when the http response was unsuccessful" do
      subject { Metapack::SoapResponse.new(Net::HTTPResponse.new(1.0, '500', '')) }
      its(:success?) { should be_false }
    end
  end

  describe "#body" do
    let(:response) { Net::HTTPResponse.new(1.0, '200', 'OK') }
    subject { Metapack::SoapResponse.new(response) }

    before :each do
      allow(response).to receive(:body).and_return('ok')
    end
    
    its(:body) { should eq('ok') }
  end
  
  describe "finders" do
    let(:xml) { xml_fixture("responses/find_ready_to_manifest_records.xml") }
    let(:response) { Net::HTTPResponse.new(1.0, '200', 'OK') }
    subject { Metapack::SoapResponse.new(response) }

    before :each do
      allow(response).to receive(:body).and_return(xml)
    end

    describe "#find" do
      it "uses css to search the doc and return the text value of the first match" do
        expect(subject.find("carrierCode")).to eq("DHL")
      end
    end

    describe "#find_all" do
      it "uses css to search the doc and return an array of hashes for specified children" do
        selector = "findReadyToManifestRecordsReturn findReadyToManifestRecordsReturn"
        expect(subject.find_all(selector, [:carrierCode, :consignmentCount])).to eq([
          { carrierCode: "DHL", consignmentCount: "1" },
          { carrierCode: "ROYALMAIL", consignmentCount: "2" },
        ])
      end
    end
  end

  
  def xml_fixture(file)
    File.read(File.join(fixture_path, "xml", file)) 
  end
end
