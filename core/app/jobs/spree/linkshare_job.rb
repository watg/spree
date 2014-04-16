module Spree
  class LinkshareJob
    include Spree::Core::Engine.routes.url_helpers

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
          if idx == 0
            xml['g'].image_link img.attachment.url(:large)
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

    def cdn_url(path)
      ['http:/', ENV['S3_HOST_ALIAS'], path].join('/')
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

    def s3_connection
      AWS::S3.new(
        access_key_id:      ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key:  ENV['AWS_SECRET_ACCESS_KEY'],
        s3_endpoint:        ENV['AWS_S3_ENDPOINT'],
      )
    end

    def storage_s3(value)
      s3_connection.buckets[ config[:s3_bucket]].
        objects[  config[:name]     ].
        write(value, :acl => :public_read)
    rescue
      notify("Linkshare Atom feed could no be saved on S3: #{value[0..400]}...")
    end

    def notify(msg)
      # Sends an email to Techadmin
      Spree::NotificationMailer.send_notification(msg)
      # fail job
      raise msg
    end

    def entry_url(v)
      ppage = v.product.
        product_group.
        product_pages.
        where(target_id: v.target.try(:id)).
        first

      tab = (v.product.assembly? || v.assembly_definition.present? ) ? "knit-your-own" : "made-by-the-gang"

      params = {
        host:       config[:host],
        id:         ppage.permalink,
        tab:        tab}
      params.merge!(variant_id: v.number) if tab == 'made-by-the-gang'
      product_page_url(params)
    end

    def data_source
      Spree::Variant.
        includes(:targets, :prices, :option_values, :images, product: [product_group: [:product_pages]] ).
        where("spree_products.product_type NOT IN (?)", %w(virtual_product parcel)).
        references(:products)
    end

    def variants
      data_source.find_in_batches(batch_size: 100) do |batch|
        batch.each do |variant|
          next if variant.is_master_but_has_variants?
          variant.targets.each do |t|
            ppage = variant.product.
              product_group.
              product_pages.
              where(target_id: t.id).first
            yield variant.decorate(context: {target: t}) if ppage 
          end
        end
      end
    end

  end
end
