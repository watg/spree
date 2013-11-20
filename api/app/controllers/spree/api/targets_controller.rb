module Spree
  module Api
    class TargetsController < Spree::Api::BaseController
      respond_to :json

      def index
        @targets = Spree::Target.all
        respond_with @targets
      end
    end
  end
end
