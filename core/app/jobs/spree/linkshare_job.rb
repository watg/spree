##    atom feed validator
##    http://validator.w3.org/feed/

module Spree
  class LinkshareJob < BaseFeedJob
    NAME = 'linkshare'
    CURRENCY = 'GBP'

    def feed
      builder = Nokogiri::XML::Builder.new do |xml|

        xml.feed(atom_feed_setup_params) do
          xml.id config[:feed_url]
          xml.title "Wool And The Gang Atom Feed"
          xml.updated Time.now.utc.iso8601
          xml.link(rel: "alternate", type: "text/html", href: config[:host])
          xml.link(rel: "self", type: "application/atom+xml", href: config[:feed_url])
          xml.author {
           xml.name "Wool And The Gang"
          }

          all_variants do |suite, tab, product, variant|
            format_entry(xml, suite, tab, product, variant)
          end
        end # end feed

      end

      builder.to_xml
    end

  private

    def atom_feed_setup_params
      {
        "xml:lang" => "en-GB",
        "xmlns"    => "http://www.w3.org/2005/Atom",
        "xmlns:g"  => "http://base.google.com/ns/1.0"
      }
    end

    def format_entry(xml, suite, tab, product, variant)
      target = suite.target
      colour = colour(variant)
      size = size(variant)

      xml.entry {
        xml.id       "#{suite.permalink}/#{variant.number}"
        xml.title    product.name
        xml.summary  product.clean_description_for(target)
        xml.link(href: variant_url(suite, tab, variant))
        xml.updated  variant.updated_at.iso8601

        xml['g'].image_link variant_image_url(variant, suite, tab)

        xml['g'].price(current_price(variant), unit: CURRENCY)

        xml['g'].condition "new"

        xml['g'].gender gender(suite)

        xml['g'].item_group_id product.slug

        xml['g'].colour(colour) if colour

        xml['g'].size(size) if size

        xml['g'].product_type variant.product.marketing_type.title
      }
    end


    def gender(suite)
      case suite.target.try(:name)
      when 'Women'
        'female'
      when 'Men'
        'male'
      else
        'unisex'
      end
    end

  end
end
