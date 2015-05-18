module Embed
  class Base
    attr_reader :embed

    WIDTH = %[100%]

    def initialize(embed)
      @embed = embed
    end

    def embed_code
      %Q[<iframe src="#{uri}" width="#{WIDTH}" height="315" frameborder="0" #{opts}></iframe>]
    end

    def uri
      parse(embed)
    end
  end
end
