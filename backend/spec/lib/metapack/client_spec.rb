require "metapack/client"
require "spec_helper"

describe Metapack::Client do
  describe ".request" do
    let(:code) { "200" }
    let(:soap_response) do
      http_response = double(code: code)
      Metapack::SoapResponse.new(http_response)
    end

    it "calls Metapack::SoapRequest" do
      expect(Metapack::SoapRequest).to receive(:do)
        .with(:service, :action, :context)
        .and_return(soap_response)
      expect(described_class.request(:service, :action, :context)).to eq(soap_response)
    end

    context "when the request is not successful" do
      let(:code) { "500" }

      it "raises an error" do
        allow(Metapack::SoapRequest).to receive(:do).and_return(soap_response)
        expect { described_class.request(:service, :action) }.to raise_error
      end
    end
  end

  describe ".create_and_allocate_consignment_with_booking_code" do
    let(:xml) { xml_fixture("responses/create_and_allocate_consignments_with_booking_code.xml") }
    let(:soap_response) do
      http_response = double(code: "200", body: xml)
      Metapack::SoapResponse.new(http_response)
    end

    it "extracts the consignment details from the soap response" do
      tracking = {
        reference: "45",
        metapack_tracking_code: "000000252",
        metapack_tracking_url: "http://www.parcelforce.com/track-trace?trackNumber=000000252"
      }

      expect(described_class).to receive(:request)
        .with(:AllocationService,
              :create_and_allocate_consignments_with_booking_code,
              consignment: :consignment)
        .and_return(soap_response)
      response = described_class.create_and_allocate_consignment_with_booking_code(:consignment)
      expect(response).to eq(
                               metapack_consignment_code: "DMC0H200CZ8W",
                               tracking: [tracking],
                               metapack_status: "Allocated",
                               carrier: "PLFCWI"
                               )
    end
  end

  describe ".find_ready_to_manifest_records" do
    let(:xml) { xml_fixture("responses/find_ready_to_manifest_records.xml") }
    let(:soap_response) do
      http_response = double(code: "200", body: xml)
      Metapack::SoapResponse.new(http_response)
    end

    it "extracts the manifest details from the soap response" do
      expect(described_class).to receive(:request)
        .with(:ManifestService, :find_ready_to_manifest_records)
        .and_return(soap_response)
      response = described_class.find_ready_to_manifest_records
      expect(response).to eq([
        { carrier: "DHL", consignment_count: "1", parcel_count: "2" },
        { carrier: "ROYALMAIL", consignment_count: "2", parcel_count: "2" }
      ])
    end
  end

  describe ".create_label_as_pdf" do
    let(:soap_response) do
      http_response = double(code: "200", body: xml_fixture("responses/create_labels_as_pdf.xml"))
      Metapack::SoapResponse.new(http_response)
    end

    it "downloads the label and returns the base64 decoded PDF" do
      expect(described_class).to receive(:request)
        .with(:ConsignmentService, :create_labels_as_pdf, consignment_code: 12_345)
        .and_return(soap_response)
      # I encoded this string and put it into the xml fixture. It's easier to
      # check than a whole PDF.
      expect(described_class.create_labels_as_pdf(12_345)).to eq("decoded content")
    end
  end

  describe ".create_manifest" do
    let(:create_soap_response) do
      http_response = double(code: "200", body: xml_fixture("responses/create_manifest.xml"))
      Metapack::SoapResponse.new(http_response)
    end
    let(:print_soap_response) do
      http_response = double(code: "200", body: xml_fixture("responses/create_manifest_as_pdf.xml"))
      Metapack::SoapResponse.new(http_response)
    end

    it "creates the manifest" do
      expect(described_class).to receive(:request)
        .with(:ManifestService, :create_manifest, carrier: "DHL")
        .and_return(create_soap_response)
      allow(described_class).to receive(:request)
        .with(:ManifestService, :create_manifest_as_pdf, anything)
        .and_return(print_soap_response)
      described_class.create_manifest("DHL")
    end

    it "uses the manifest code to download the documentation" do
      allow(described_class).to receive(:request)
        .with(:ManifestService, :create_manifest, anything)
        .and_return(create_soap_response)
      expect(described_class).to receive(:request)
        .with(:ManifestService, :create_manifest_as_pdf, manifest: "DMM006YQS")
        .and_return(print_soap_response)
      described_class.create_manifest("DHL")
    end

    it "returns the base64 decoded PDF" do
      allow(described_class).to receive(:request)
        .with(:ManifestService, :create_manifest, anything)
        .and_return(create_soap_response)
      allow(described_class).to receive(:request)
        .with(:ManifestService, :create_manifest_as_pdf, manifest: "DMM006YQS")
        .and_return(print_soap_response)
      # I encoded this string and put it into the xml fixture. It's easier to
      # check than a whole PDF.
      expect(described_class.create_manifest("DHL")).to eq("decoded content")
    end
  end

  def xml_fixture(file)
    File.read(File.join(fixture_path, "xml", file))
  end
end
