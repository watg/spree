require "spec_helper"

describe Metapack::SoapTemplate do
  let(:consignment) { :consignment_data }
  subject { described_class.new(:manifest, consignment: consignment) }

  describe "#consignment" do
    subject { super().consignment }
    it { is_expected.to eq(consignment) }
  end

  describe "#template_path" do
    subject { super().template_path }
    it { is_expected.to match(%r{/templates/manifest.xml.erb$}) }
  end

  describe "xml" do
    let(:label_path) { File.join(fixture_path, "xml/label.xml.erb") }
    let(:fixture) { File.read(label_path) }
    subject { described_class.new(:manifest) }

    it "calls ERB#result with the binding" do
      allow(subject).to receive(:template_path).and_return(label_path)
      allow(subject).to receive(:binding).and_return(:binding)
      erb = double
      allow(ERB).to receive(:new).with(fixture, 0, ">").and_return(erb)

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
