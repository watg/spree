module Spree
  module Api
    class LinkshareController < Spree::Api::BaseController
      include Rails.application.routes.url_helpers

      respond_to :xml, :atom, only: :index

      def index
        variants = Spree::Variant.
          accessible_by(current_ability, :read).
          page(params[:page]).
          per(params[:per_page])
        
        @variants = VariantDecorator.decorate_collection(variants)
        respond_with(@variants)
      end
    end
  end
end
