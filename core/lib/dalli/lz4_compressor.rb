# Provides helper methods for dalli
require 'lz4-ruby'
module Dalli
  class LZ4Compressor
    def self.compress(data)
      LZ4::compress(data)
    end
    def self.decompress(data)
      LZ4::uncompress(data)
    end
  end
  class LZ4HCCompressor < LZ4Compressor
    def self.compress(data)
      LZ4::compressHC(data)
    end
  end
end
