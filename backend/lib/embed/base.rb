module Embed
  class Base
    attr_reader :url

    WIDTH = %[100%]

    def initialize(url)
      @url = parse(url)
    end

    def embed_code
      %Q[<iframe src="#{url}" width="#{WIDTH}" height="315" frameborder="0" #{opts}></iframe>]
    end
  end
end
