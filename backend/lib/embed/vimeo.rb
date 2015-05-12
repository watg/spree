module Embed
  class Vimeo < Base
    def parse(uri)
      'https://player.vimeo.com/video/' + uri.split('/').last
    end

    def opts
      %[webkitallowfullscreen mozallowfullscreen allowfullscreen]
    end
  end
end
