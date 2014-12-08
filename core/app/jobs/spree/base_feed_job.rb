module Spree
  class BaseFeedJob
    BRAND = 'Wool and the Gang'
    DEFAULT_IMAGE_URL = nil
    CURRENCY = 'USD'

    def initialize
    end

    def perform
      persist( feed, config[:storage_method].to_sym)
    end

    def feed
      raise '#feed should be implemented in a sub-class of Spree::BaseFeedJob'
    end

    def name
      raise '#name should be implemented in a sub-class of Spree::BaseFeedJob'
    end



  protected

    ## Config & Storage methods

    def config
      FEEDS_CONFIG[self.class::NAME].symbolize_keys
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
        notify("#{self.class::NAME} feed could no be saved in CACHE path #{path}: #{value[0..100]}...")
      end
    end

    def storage_s3(value)
      s3_connection.buckets[ config[:s3_bucket]].
        objects[  config[:name]     ].
        write(value, :acl => :public_read)
    rescue
      notify("#{self.class::NAME} feed could no be saved on S3: #{value[0..400]}...")
    end

    def s3_connection
      AWS::S3.new(
        access_key_id:      ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key:  ENV['AWS_SECRET_ACCESS_KEY'],
        s3_endpoint:        ENV['AWS_S3_ENDPOINT'],
      )
    end

    def notify(alert_message)
      Helpers::AirbrakeNotifier.delay.notify(alert_message)
    end



    ## Suite, Product & Variant accessor methods

    def all_variants
      all_suites.each do |suite|
        suite.tabs.each do |tab|
          product = tab.product
          next unless product

          product.variants_including_master.each do |variant|
            yield(suite, tab, product, variant)
          end
        end
      end
    end

    def all_suites
      Spree::Suite.includes(tabs: [ product: [ :variants ]]).uniq
    end

    def current_price(variant)
      variant.current_price_in(self.class::CURRENCY).amount.to_f
    end

    def colour(variant)
      variant.option_values.detect{ |ov| ov.option_type.is_color? }.try(:presentation)
    end

    def size(variant)
      variant.option_values.detect{ |ov| ov.option_type.is_size? }.try(:presentation)
    end

    def route
      Spree::Core::Engine.routes.url_helpers
    end

    def variant_url(suite, tab, variant)
      # this takes care of links to products with assembly definitions
      if variant.is_master?
        route.suite_url(suite, tab.tab_type)
      else
        route.suite_url(suite, tab.tab_type, variant.number)
      end
    end

    def variant_image_url(variant, suite, tab)
      target = suite.target
      image = variant.images_for(target).first
      image = image ? image : variant.product.images_for(target).first
      image = image ? image : tab.image
      image.present? ? image.attachment.url(:product) : DEFAULT_IMAGE_URL
    end

  end


end
