require 'spec_helper'

describe Metapack::SoapRequest do
  subject { Metapack::SoapRequest }

  describe ".do" do
    let(:envelope) { :soap_envelope }
    before :each do
      allow(Metapack::Config).to receive(:service_base_url).and_return("/ServiceBase")
      allow(Metapack::Config).to receive(:host).and_return("test.host")
      allow(Metapack::Config).to receive(:username).and_return("test_username")
      allow(Metapack::Config).to receive(:password).and_return("test_password")

      allow(subject).to receive(:envelope).
        with(:soap_action_and_template_name, :template_binding).
        and_return(envelope)
    end

    it "makes an http request to metapack" do
      stub = stub_request(
            :post,
            "http://test_username:test_password@test.host/ServiceBase/ServiceName").
        with(:body => envelope,
        :headers => {
          'User-Agent'      => 'WATG',
          'SOAPAction'      => 'soapActionAndTemplateName',
          'Content-Type'    => 'text/xml;charset=UTF-8',
        })

      subject.do(:ServiceName, :soap_action_and_template_name, :template_binding)
      expect(stub).to have_been_requested
    end

    it "returns a SoapResponse created from the http response" do
      stub_request(:post, "http://test_username:test_password@test.host/ServiceBase/ServiceName").to_return(status: 200, body: "response body")

      expect(Metapack::SoapResponse).to receive(:new) do |response|
        expect(response).to be_a(Net::HTTPResponse)
        expect(response.code).to eq("200")
        expect(response.body).to eq("response body")
      end
      subject.do(:ServiceName, :soap_action_and_template_name, :template_binding)
    end
  end

  describe ".url" do
    it "concats the service base url with the service name" do
      allow(Metapack::Config).to receive(:service_base_url).and_return("ServiceBase")
      expect(subject.url(:ServiceName)).to eq("ServiceBase/ServiceName")
    end
  end

  describe ".envelope" do
    it "passes template name and binding to SoapTemplate" do
      template = double
      allow(template).to receive(:xml)

      template_name = :template
      template_binding = :binding

      expect(Metapack::SoapTemplate).to receive(:new).
        with(template_name, template_binding).
        and_return(template)
      subject.envelope(template_name, template_binding)
    end
 
    it "returns the xml from SoapTemplate" do
      template = double
      allow(template).to receive(:xml).and_return(:xml)
      allow(Metapack::SoapTemplate).to receive(:new).and_return(template)

      expect(subject.envelope(:template_name, nil)).to eq(:xml)
    end
  end

  # Metapack::SoapRequest.do(:ManifestService, :find_ready_to_manifest_records, warehouse: "DEFAULT")

end
