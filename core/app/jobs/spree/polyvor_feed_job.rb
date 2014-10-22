module Spree
  class PolyvorFeedJob
    include ActionView::Helpers
    include ApplicationHelper

    NAME = 'polyvor'

    CURRENCY = 'USD'
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
    CATEGORY = 'Clothing'
    BRAND = 'Wool and the Gang'

    # TODO: what about out of stock products?
    # TODO this needs to be implemented
    # TODO: we need to set this up to be hosted on S3 like the linkshare job
    # TODO: it needs to refreshed once a day
    DEFAULT_IMAGE_URL = nil

    def initialize

    end

    def header
      HEADER
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
      if storage_method == :s3
        storage_s3(value)
      else
        storage_cache(value)
      end
    end

    def storage_cache(value)
      path = File.join(Rails.root,'public', config[:name])
      unless open(path, 'w') { |f| f.write(value); f.flush }
        notify("#{NAME} feed could no be saved in CACHE path #{path}: #{value[0..100]}...")
      end
    end

    def storage_s3(value)
      s3_connection.buckets[ config[:s3_bucket]].
        objects[  config[:name]     ].
        write(value, :acl => :public_read)
    rescue
      notify("#{NAME} feed could no be saved on S3: #{value[0..400]}...")
    end

    def s3_connection
      AWS::S3.new(
        access_key_id:      ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key:  ENV['AWS_SECRET_ACCESS_KEY'],
        s3_endpoint:        ENV['AWS_S3_ENDPOINT'],
      )
    end

    def notify(alert_message)
      # Sends an email to Techadmin
      Spree::NotificationMailer.delay.send_notification(alert_message, Rails.application.config.tech_email_list)
    end

    def feed
      CSV.generate(col_sep: "\t") do |csv|
        csv << header
        all_product_pages = Spree::ProductPage.joins(tabs: [:product]).includes(tabs: [ product: [ :variants ]])
        all_product_pages.each do |product_page|
          target = product_page.target
          product_page.tabs.each do |tab|
            if product = tab.product
              if product.product_type.is_assembly?
                variant = product.master
                csv << format_csv(product_page, tab, product, variant)
              else
                product.variants.each do |variant|
                  csv << format_csv(product_page, tab, product, variant)
                end
              end
            end
          end
        end
      end
    end

    def format_csv(product_page, tab, product, variant)
      [
        product_page.name, # title
        BRAND, # brand
        find_product_page_url(product_page, tab, variant), # url
        nil, # cpc_tracking_url
        variant_image_url(variant, product_page, tab), # imgurl
        variant.price_normal_in(CURRENCY).amount, # price
        sale_price(variant), # sale_price
        CURRENCY,
        product.clean_description_for(product_page.target), # description
        safe_colour(variant), # color
        nil, # sizes
        nil, # tags
        target(product_page), # target
        CATEGORY, # category
        nil, # cpc_labels
      ]
    end

    def target(product_page)
      product_page.target ? product_page.target.name.humanize : 'Unknown'
    end

    def sale_price(variant)
      price = variant.price_normal_sale_in(CURRENCY)
      price.sale? ? price.amount : nil
    end

    def safe_colour(variant)
      option_value = variant.option_values.detect{ |ov| ov.option_type.is_color? }
      option_value.present? ?  option_value.presentation : nil
    end

    def route
      Spree::Core::Engine.routes.url_helpers
    end

    def find_product_page_url(product_page, tab, variant)
      v = variant.is_master ? nil : variant #does this line do anything important???
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
