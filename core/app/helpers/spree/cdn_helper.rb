module Spree
  module CdnHelper

    def cdn_image_tag(source, options={})
      options = options.symbolize_keys

      src = options[:src] = cdn_url(source)

      unless src =~ /^(?:cid|data):/ || src.blank?
        options[:alt] = options.fetch(:alt){ image_alt(src) }
      end

      if size = options.delete(:size)
        options[:width], options[:height] = size.split("x") if size =~ %r{\A\d+x\d+\z}
        options[:width] = options[:height] = size if size =~ %r{\A\d+\z}
      end

      tag("img", options)
    end

    def cdn_link_to(name = nil, options = nil, html_options = nil, &block)

      html_options, options, name = options, name, block if block_given?

      options ||= {}

      html_options = convert_options_to_data_attributes(options, html_options)

      url = cdn_url(url_for(options))

      html_options['href'] ||= url

      content_tag(:a, name || url, html_options, &block)
    end

    def cdn_url(source)

      u_source = parse_source_for_environment(source)

      u_source_query =  u_source.query ? "?#{u_source.query}" : ''

      if u_source.path[0] == '/'
        [cdn_prefix, u_source.path].join + u_source_query
      else
        [cdn_prefix, "/", u_source.path].join + u_source_query
      end
    end

    def cdn_prefix
      @_cdn_prefix ||= Spree::Config[:asset_cdn_url]
    end

    def parse_source_for_environment(source)

      if Rails.env.test? or Rails.env.features?
        URI('')
      else
        URI(source)
      end

    end

  end
end
