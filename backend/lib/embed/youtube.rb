module Embed
  class Youtube < Base
    private
    
    def parse(uri)
      uri.sub('watch?v=', 'embed/')
    end

    def opts
      %[allowfullscreen]
    end
  end
end
