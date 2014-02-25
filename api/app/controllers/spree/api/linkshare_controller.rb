module Spree
  module Api
    class LinkshareController < Spree::Api::BaseController
      include Rails.application.routes.url_helpers

      respond_to :xml, :atom, only: :index

      def index
        data = Rails.cache.read(Spree::LinkshareJob::FEED_NAME)
        respond_to do |format|
          format.xml  { data }
          format.atom { data }
        end
      end
    end
  end
end
