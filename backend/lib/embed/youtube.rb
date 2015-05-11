module Embed
  class Youtube
    attr_reader :video

    WIDTH = 460

    def initialize(video)
      @video = video
    end

    def embed_code
      %Q[<iframe src="#{uri}" width="#{WIDTH}" height="315" frameborder="0" #{opts}></iframe>]
    end

    def uri
      parse(video.embed)
    end

    def parse(uri)
      uri.sub('watch?v=', 'embed/')
    end

    def opts
      %[allowfullscreen]
    end
  end
end
