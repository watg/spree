module Spree
  class LinkshareJob
    include Spree::Core::Engine.routes.url_helpers
    include CdnHelper

    FEED_NAME = 'linkshare_feed'

    def perform
      set_cache(FEED_NAME, feed)
    end

    def feed
      builder = Nokogiri::XML::Builder.new {|xml| 
        xml.feed("xml:lang" => "en-GB", 
                 "xmlns"    => "http://www.w3.org/2005/Atom", 
                 "xmlns:g"  => "http://base.google.com/ns/1.0", 
                 "xmlns:c"  => "http://base.google.com/cns/1.0") { 
          xml.id_ "linkshare-atom-feed"
          xml.title "Wool And The Gang Atom Feed"
          xml.updated_at Time.now.iso8601
          xml.link(rel: "alternate", type: "text/html", href: host)
          xml.link(rel: "self", type: "application/atom+xml", href: api_linkshare_index_url(host: host))
          xml.link api_linkshare_index_url(host: host)
          xml.author {
            xml.nane "Wool And The Gang" }
          
          variants {|v| 
            entry(xml, v) }}}

      builder.to_xml
    end
    
    def entry(xml, variant)
      xml.entry {
        xml.title    variant.name
        xml.id_      variant.number
        xml.link     
        xml.summary  variant.product.description
        xml.updated_at variant.updated_at.iso8601
        
        variant.images.each_with_index {|img, idx|
          src = cdn_url(img.attachment.url(:large))
          if idx == 0
            xml['g'].image_link src
          else
            xml['g'].additional_image_link src
          end 
        }
        
        xml['g'].price variant.price_with_currency
        xml['g'].condition "new"
        xml['g'].availability "in stock"
        xml['g'].gender variant.target.try(:name)
        
        xml['g'].color variant.color_and_size_option_values[:color]
        xml['g'].size  variant.color_and_size_option_values[:size]
        
        if variant.product.product_type.respond_to?(:name)
          xml['g'].google_product_category variant.product.category
          xml['g'].product_type variant.product.product_type.name
        else
          xml['g'].product_type variant.product_type
        end 
      }
    end

    private
    def set_cache(key, value)
      puts "SIZE: #{value.size}"
      puts  value[2..500]
      puts "key: #{key}"
      
      open(File.join(Rails.root, 'tmp/atom.xml'), 'w'){|f| f.write(value); f.flush }
      Rails.cache.write(key, value)
      puts "real result #{res}"
    end

    def host
      "http://www.woolandthegang.com"
    end

    def product_page_url(v)
      ppage = v.product.
        product_group.
        product_pages.
        where(target_id: v.target.try(:id)).
        first

      tab = v.product.is_kit? ? "knit-your-own" : "made-by-the-gang"

      product_page_url(host:       host, 
                       id:         ppage.permalink, 
                       tab:        tab,
                       variant_id: variant.number)
    end
    
    def variants
      Spree::Variant.
        includes(:product).
        where("spree_products.product_type NOT IN (?)", %w(virtual_product parcel)).
        find_in_batches(batch_size: 100) do |batch|
           batch.each { |variant| 
              variant.targets.each {|t| 
                yield variant.decorate(context: {target: t}) }
           }
      end      
    end

  end
end
