require 'spec_helper'

describe Metapack::SoapTemplate do
  let(:consignment) { :consignment_data }
  subject { Metapack::SoapTemplate.new(:manifest, consignment: consignment) }

  its(:consignment) { should eq(consignment) }
  its(:template_path) { should match(%r{/templates/manifest.xml.erb$}) }

  describe "xml" do
    let(:fixture_path) { File.join(Rails.root, "spec", "fixtures", "xml", "label.xml.erb") }
    let(:fixture) { File.read(fixture_path) }
    subject { Metapack::SoapTemplate.new(:manifest) }

    it "calls ERB#result with the binding" do
      allow(subject).to receive(:template_path).and_return(fixture_path)
      allow(subject).to receive(:binding).and_return(:binding)

      erb = double
      allow(ERB).to receive(:new).with(fixture, 0, '>').and_return(erb)

      expect(erb).to receive(:result).with(:binding).and_return(:xml)
      expect(subject.xml).to eq(:xml)
    end
  end

  describe "escape" do
    it "escapes &" do
      expect(subject.escape("Big & Small")).to eq("Big &amp; Small")
    end

    it "escapes < and >" do
      expect(subject.escape("<something>")).to eq("&lt;something&gt;")
    end
  end
end
