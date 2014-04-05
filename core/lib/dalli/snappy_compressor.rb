# Provides helper methods for dalli
module Dalli
  class SnappyCompressor
    require 'snappy'
    def self.compress(data)
      Snappy.deflate(data)
    end

    def self.decompress(data)
      Snappy.inflate(data)
    end
  end
end
