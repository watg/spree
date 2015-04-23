module Promotions
  class CodeGenerator

    attr_accessor :size, :prefix

    def initialize(size: 6, prefix: "")
      @size = size
      @prefix = prefix
    end

    def generate
      code = nil
      need_new = true
      while need_new
        charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
        code = (0...size).map{ charset.to_a[rand(charset.size)] }.join
        code = prefix + code
        need_new = Spree::Promotion.active.where(code: code).any?
      end
      code
    end

  end
end
