module Spree
  module Api
    class TagsController < Spree::Api::BaseController
      def index
        render text: Spree::Tag.all.map(&:value)
      end
    end
  end
end
