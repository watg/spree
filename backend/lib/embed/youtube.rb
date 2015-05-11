module Embed
  class Youtube < Base
    def parse(uri)
      uri.sub('watch?v=', 'embed/')
    end

    def opts
      %[allowfullscreen]
    end
  end
end
