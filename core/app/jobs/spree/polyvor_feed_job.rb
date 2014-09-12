module Spree
  class PolyvorFeedJob
    include ActionView::Helpers
    include ActionDispatch::Routing
    include Rails.application.routes.url_helpers
    include ApplicationHelper

    NAME = 'polyvor'

    DEFAULT_CURRENCY = 'GBP'
    COLOUR = 'color'
    HEADER = [
        'title',
        'brand',
        'url',
        'cpc_tracking_url',
        'imgurl',
        'price',
        'sale_price',
        'currency',
        'description',
        'color',
        'sizes',
        'tags',
        'category',
        'cpc_labels'
      ]

    # TODO: what about out of stock products?
    # TODO this needs to be implemented
    # TODO: we need to set this up to be hosted on S3 like the linkshare job
    # TODO: it needs to refreshed once a day
    DEFAULT_IMAGE_URL = nil

    def initialize

    end

    def perform
      persist( feed, config[:storage_method].to_sym)
    end

    private

    def config
      FEEDS_CONFIG[NAME].symbolize_keys
    end

    def persist(value, storage_method=:s3)
      notify("storage_method : #{storage_method} not supported") unless [:cache, :s3].include?(storage_method)
      send("storage_#{storage_method}".to_sym, value)
    end

    def storage_cache(value)
      path = File.join(Rails.root,'public', config[:name])
      unless open(path, 'w') {|f| 
        f.write(value); f.flush }
        notify("#{NAME} feed could no be saved in CACHE path #{path}: #{value[0..100]}...")
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
      notify("#{NAME} feed could no be saved on S3: #{value[0..400]}...")
    end

    def notify(msg)
      # Sends an email to Techadmin
      Spree::NotificationMailer.send_notification(msg)
      # fail job
      raise msg
    end

    def feed
      CSV.generate(col_sep: "\t") do |csv|
        csv << header
        pps = Spree::ProductPage.joins(tabs: [:product]).includes(tabs: [ product: [ :variants ]])
        pps.each do |pp|
          target = pp.target
          pp.tabs.each do |tab|
            if p = tab.product
              if p.product_type.is_assembly?
                v = p.master
                csv << format_csv(pp, tab, p, v)
              else
                p.variants.each do |v|
                  csv << format_csv(pp, tab, p, v)
                end
              end
            end
          end
        end
      end
    end

    private

    def header
      HEADER
    end

    def format_csv(product_page, tab, product, variant)
      [
        product_page.name, # title
        tab.presentation, # brand 
        pp_url(product_page, tab, variant), # url
        nil, # cpc_tracking_url 
        variant_image_url(variant, product_page, tab), # imgurl
        variant.price_normal_in(DEFAULT_CURRENCY).amount, # price
        sale_price(variant), # sale_price
        product.clean_description_for(product_page.target), # description
        safe_colour(variant), # color
        nil, # sizes
        nil, # tags
        subject(product_page), # subject
        nil, # category
        nil, # cpc_labels
      ]
    end

    def subject(product_page)
      product_page.target ? product_page.target.name.humanize : nil
    end

    def sale_price(variant)
      price = variant.price_normal_sale_in(DEFAULT_CURRENCY)
      price.sale? ? price.amount : nil
    end

    def safe_colour(variant)
      option_value = variant.option_values.detect{ |ov| ov.option_type.name = COLOUR }
      option_value.present? ?  option_value.presentation : nil
    end

    def route
      Spree::Core::Engine.routes.url_helpers
    end

    def pp_url(product_page, tab, variant)
      v = variant.is_master ? nil : variant
      route.product_page_url(product_page, tab.url_safe_tab_type, v)
    end

    def variant_image_url(variant, product_page, tab)
      target = product_page.target
      image = variant.images_for(target).first
      image = image ? image : variant.product.images_for(target).first
      image = image ? image : tab.image
      image ? image.attachment.url(:product) : DEFAULT_IMAGE_URL
    end

  end


end

result =  Spree::PolyvorFeedJob.new.perform 
d{ result }

