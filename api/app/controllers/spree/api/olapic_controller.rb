module Spree
  module Api
    class OlapicController < Spree::Api::BaseController
      skip_before_filter :check_for_user_or_api_key
      skip_before_filter :authenticate_user

      include Rails.application.routes.url_helpers
      def index
        @suites = Spree::Suite.accessible_by(current_ability, :read)
        @suites = @suites.page(params[:page]).per(params[:per_page])
        respond_with(@suites)
      end

    end
  end
end
