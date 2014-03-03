module Spree
  class LinkshareJob
    include Spree::Core::Engine.routes.url_helpers
    include Spree::CdnHelper

    def perform
      persist( feed, config[:storage_method].to_sym)
    end

    def feed
      ##    atom feed validator
      ##    http://validator.w3.org/feed/

      builder = Nokogiri::XML::Builder.new {|xml| 
        xml.feed("xml:lang" => "en-GB", 
                 "xmlns"    => "http://www.w3.org/2005/Atom", 
                 "xmlns:g"  => "http://base.google.com/ns/1.0") { 
          xml.id_ config[:feed_url]
          xml.title "Wool And The Gang Atom Feed"
          xml.updated Time.now.iso8601
          xml.link(rel: "alternate", type: "text/html", href: config[:host])
          xml.link(rel: "self", type: "application/atom+xml", href: config[:feed_url])
          xml.author {
            xml.name "Wool And The Gang" }
          
          variants {|v| entry(xml, v) }}}

      builder.to_xml
    end
    
    def entry(xml, variant)
      xml.entry {
        xml.title    variant.name
        xml.id_      variant.number
        xml.summary  variant.product.description
        xml.link(href: entry_url(variant))
        xml.updated  variant.updated_at.iso8601
        
        variant.images.each_with_index {|img, idx|
          src = "http:"+cdn_url(img.attachment.url(:large))
          if idx == 0
            xml['g'].image_link src
          else
# TODO: including it breaks atom validity
#            xml['g'].additional_image_link src
          end 
        }

        xml['g'].price "#{variant.current_price_in("GBP").amount.to_f} GBP"
        xml['g'].condition "new"

        xml['g'].gender gender(variant)
                
        (variant.color_and_size_option_values[:color] || []).each do |opt|
          xml['g'].color opt.presentation
        end

        (variant.color_and_size_option_values[:size] || []).each do |opt|
          xml['g'].size opt.presentation
        end
                
        if variant.product.product_type.respond_to?(:name)
          xml['g'].google_product_category variant.product.category
          xml['g'].product_type variant.product.product_type.name
        else
          xml['g'].product_type variant.product_type
        end 
      }
    end

    private
    def config
      FEEDS_CONFIG['linkshare'].symbolize_keys
    end

    def gender(v)
      t = v.target.try(:name)
      (t.downcase == 'women' ? "F" : "M")
    end

    def persist(value, storage_method=:s3)
      notify("storage_method : #{storage_method} not supported") unless [:cache, :s3].include?(storage_method)
      send("storage_#{storage_method}".to_sym, value)
    end

    def storage_cache(value)
      path = File.join(Rails.root,'public', config[:name])
      unless open(path, 'w') {|f| 
          f.write(value); f.flush }
        notify("Linkshare Atom feed could no be saved in CACHE path #{path}: #{value[0..100]}...")
      end
    end

    def storage_s3(value)
      s3 = AWS::S3.new
      s3.buckets[ config[:s3_bucket]].
        objects[  config[:name]     ].
        write(value)
    rescue
      notify("Linkshare Atom feed could no be saved on S3: #{value[0..400]}...")
    end

    def notify(msg)
      # Sends an email to Techadmin
      NotificationMailer.send_notification(msg)
      # fail job
      raise msg
    end

    def entry_url(v)
      ppage = v.product.
        product_group.
        product_pages.
        where(target_id: v.target.try(:id)).
        first

      tab = v.product.assembly? ? "knit-your-own" : "made-by-the-gang"

      product_page_url(host:       config[:host], 
                       id:         ppage.permalink, 
                       tab:        tab,
                       variant_id: v.number)
    end
    
    def data_source
      Spree::Variant.
        includes(:product).
        where("spree_products.product_type NOT IN (?)", %w(virtual_product parcel)).
        references(:products)
    end
    
    def variants
      data_source.
        find_in_batches(batch_size: 100) do |batch|
          batch.each { |variant|
            variant.targets.each {|t| 
              ppage = variant.product.
                     product_group.
                     product_pages.
                     where(target_id: t.id).first
              yield variant.decorate(context: {target: t}) if ppage }
          }
      end
    end

  end
end
