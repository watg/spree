require File.join(File.dirname(__FILE__), '..','spec_helper')

describe Spree::LinkshareJob do
  describe :variants do
    it "loads only the variants that are accessible with a url endpoint" do
      block = Proc.new do |actual_variant| 
        expect(actual_variant.product_type).to_not include('virtual_product', 'parcel')
      end
      subject.send(:variants) &block
    end
  end

  describe :feed do
    let(:time) { Time.new(2008, 9, 1, 12, 0, 0,"-04:00") }
    before do
      allow(subject).to receive(:variants).and_return([])
      allow(nil).to receive(:permalink).and_return("a")
    end

    it "generates base" do
      Timecop.freeze(time)
      Time.use_zone("London") do
#        expect(subject.feed).to eql(feed_fixture(time))
        actual =  Nokogiri::XML(subject.feed)
        expect(actual.css("feed id").text).to eql("http://localhost:3000/linkshare-atom.xml")
        expect(actual.css("feed title").text).to eql("Wool And The Gang Atom Feed")
        expect(actual.css("feed author name").text).to eql("Wool And The Gang")
      end
    end
    
    it "generates atom entry" do
      target = create(:target)
      product = create(:product, name: "my cool product")
      variant = create(:variant, number: 'V307238112', product: product).
        decorate(context: {target: target})
      allow(variant).to receive(:updated_at).and_return(time)
      feed = Nokogiri::XML::Builder.new {|xml| 
        xml.feed("xml:lang" => "en-GB", 
                 "xmlns"    => "http://www.w3.org/2005/Atom", 
                 "xmlns:g"  => "http://base.google.com/ns/1.0") { 
          subject.entry(xml, variant) }}
      
      Timecop.freeze(time) 
      Time.use_zone("London") do
#        expect(feed.to_xml).to eql(entry_fixture(time))
        actual =  Nokogiri::XML(feed.to_xml)
        expect(actual.css("entry id").text).to eql("V307238112")
        expect(actual.css("entry title").text).to eql("my cool product")
        expect(actual.css("entry summary").text).to eql("")
      end
    end
  end

  describe "Error handling" do
    it "does not know storage method" do
      expect(subject).to receive(:notify)
      expect { subject.send(:persist, "data to store", :fake_method) }.to raise_error
    end
  end

  private
  def feed_fixture(t)
<<EOF
<?xml version=\"1.0\"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:g="http://base.google.com/ns/1.0" xml:lang="en-GB">
  <id>http://localhost:3000/linkshare-atom.xml</id>
  <title>Wool And The Gang Atom Feed</title>
  <updated>#{t.iso8601}</updated>
  <link rel="alternate" type="text/html" href="http://www.woolandthegang.com"/>
  <link rel="self" type="application/atom+xml" href="http://localhost:3000/linkshare-atom.xml"/>
  <author>
    <name>Wool And The Gang</name>
  </author>
</feed>
EOF
  end

  def entry_fixture(t)
<<EOF
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:g="http://base.google.com/ns/1.0" xml:lang="en-GB">
  <entry>
    <title>my cool product</title>
    <id>V307238112</id>
    <summary/>
    <link href="http://www.woolandthegang.com/shop/items/a/made-by-the-gang/V307238112"/>
    <updated>#{t.iso8601}</updated>
    <g:price>0.0 GBP</g:price>
    <g:condition>new</g:condition>
    <g:gender>M</g:gender>
    <g:color>Hot Pink</g:color>
    <g:product_type>product</g:product_type>
  </entry>
</feed>
EOF
  end
end
