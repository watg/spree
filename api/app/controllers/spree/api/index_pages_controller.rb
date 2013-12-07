module Spree
  module Api
    class IndexPagesController < Spree::Api::BaseController
      def index
        if params[:id]
          @index_pages = Spree::IndexPage.accessible_by(current_ability, :read).where(id: params[:id])
        else
          @index_pages = Spree::IndexPage.accessible_by(current_ability, :read).order(:name).ransack(params[:q]).result
        end

        @index_pages = @index_pages.page(params[:page]).per(params[:per_page])
        respond_with(@index_pages)
      end

    end
  end
end
