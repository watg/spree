require File.join(File.dirname(__FILE__), '..','spec_helper')

describe Spree::LinkshareJob do
  let(:suite)   { Spree::Suite.new(target: target, permalink: 'suite-perma') }
  let(:tab)     { Spree::SuiteTab.new(tab_type: 'some-tab-permalink', product: product) }
  let(:product) { Spree::Product.new(name: "My Cool Product", description: "Descipt", slug: 'product-slug') }
  let(:variant) { Spree::Variant.new(in_stock_cache: true, number: "V1234", updated_at: time) }
  let(:target)  { Spree::Target.new(name: "Women") }
  let(:marketing_type)  { Spree::MarketingType.new(title: "Yarn") }

  let(:time) { Time.now.utc }
  before { Timecop.freeze(time) }
  after { Timecop.return }

  describe "#feed" do
    it "generates an xml base" do
      generated_xml = subject.feed

      expect(generated_xml).to eq feed_fixture(time)

      actual =  Nokogiri::XML(generated_xml)
      expect(actual.css("feed id").text).to eql("http://localhost:3000/linkshare-atom.xml")
      expect(actual.css("feed title").text).to eql("Wool And The Gang Atom Feed")
      expect(actual.css("feed author name").text).to eql("Wool And The Gang")
    end
  end

  describe "#format_entry" do

    before do
      variant.product = product
      variant.current_price_in("GBP").amount = 15.55
      product.marketing_type = marketing_type
      allow(subject).to receive(:all_suites).and_return [suite]
    end

    it "generates atom entry for a variant" do
      xml_feed = Nokogiri::XML::Builder.new do |xml|
        xml.feed(subject.send(:atom_feed_setup_params)) do
            subject.send(:format_entry, xml, suite, tab, product, variant)
        end
      end.to_xml

      actual =  Nokogiri::XML(xml_feed)
      expect(actual.css("entry id").text).to eql("suite-perma/V1234")
      expect(actual.css("entry title").text).to eql("My Cool Product")
      expect(actual.css("entry summary").text).to eql("Descipt")
      expect(actual.css("entry link")[0]['href']).to eql("http://www.example.com/product/suite-perma/some-tab-permalink/V1234")
      expect(actual.css("entry updated").text).to eq time.iso8601
      expect(actual.css("entry g|image_link")[0].text).to eq ""
      expect(actual.css("entry g|price").text).to eq "15.55"
      expect(actual.css("entry g|price")[0]['unit']).to eq "GBP"
      expect(actual.css("entry g|condition").text).to eq "new"
      expect(actual.css("entry g|gender").text).to eq "female"
      expect(actual.css("entry g|item_group_id").text).to eq "product-slug"
      expect(actual.css("entry g|colour").text).to eq ""
      expect(actual.css("entry g|size").text).to eq ""
      expect(actual.css("entry g|product_type").text).to eq "Yarn"


      expect(xml_feed).to eql(entry_fixture(time))
    end
  end


  describe "#atom_feed_setup_params" do
    specify do
      expected_params = {
        "xml:lang" => "en-GB",
        "xmlns"    => "http://www.w3.org/2005/Atom",
        "xmlns:g"  => "http://base.google.com/ns/1.0"
      }
      expect(subject.send(:atom_feed_setup_params)).to eq expected_params
    end
  end


  describe '#gender' do
    it "returns 'female' for target Women" do
      expect(subject.send(:gender, suite)).to eq 'female'
    end

    it "returns 'male' for target Men" do
      target.name = "Men"
      expect(subject.send(:gender, suite)).to eq 'male'
    end

    it "returns 'unisex' when target is not supplied" do
      suite.target = nil
      expect(subject.send(:gender, suite)).to eq 'unisex'
    end
  end

  private


  def feed_fixture(time)
<<EOF
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:g="http://base.google.com/ns/1.0" xml:lang="en-GB">
  <id>http://localhost:3000/linkshare-atom.xml</id>
  <title>Wool And The Gang Atom Feed</title>
  <updated>#{time.iso8601}</updated>
  <link rel="alternate" type="text/html" href="http://www.woolandthegang.com"/>
  <link rel="self" type="application/atom+xml" href="http://localhost:3000/linkshare-atom.xml"/>
  <author>
    <name>Wool And The Gang</name>
  </author>
</feed>
EOF
  end


  def entry_fixture(time)
<<EOF
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:g="http://base.google.com/ns/1.0" xml:lang="en-GB">
  <entry>
    <id>suite-perma/V1234</id>
    <title>My Cool Product</title>
    <summary>Descipt</summary>
    <link href="http://www.example.com/product/suite-perma/some-tab-permalink/V1234"/>
    <updated>#{time.iso8601}</updated>
    <g:image_link/>
    <g:price unit="GBP">15.55</g:price>
    <g:condition>new</g:condition>
    <g:gender>female</g:gender>
    <g:item_group_id>product-slug</g:item_group_id>
    <g:product_type>Yarn</g:product_type>
  </entry>
</feed>
EOF
  end
end
