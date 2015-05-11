module Embed
  class Vimeo
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
      'https://player.vimeo.com/video/' + uri.split('/').last
    end

    def opts
      %[webkitallowfullscreen mozallowfullscreen allowfullscreen]
    end
  end
end
