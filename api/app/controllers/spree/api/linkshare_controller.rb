module Spree
  module Api
    class LinkshareController < Spree::Api::BaseController
      include Rails.application.routes.url_helpers

      respond_to :xml, :atom, only: :index

      def index
        data = Rails.cache.read(Spree::LinkshareJob::FEED_NAME)
        respond_to do |format|
          format.xml  { 
            render xml: proc {|response, output|
              output.write data
            }}
          format.atom { render atom: proc {|response, output|
              output.write data
            }}
        end
      end
    end
  end
end
