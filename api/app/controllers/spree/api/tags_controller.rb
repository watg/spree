module Spree
  module Api
    class TagsController < Spree::Api::BaseController

      def index
        if params[:ids]
          @tags = Spree::Tag.where(id: params[:ids].split(','))
        else
          @tags = Spree::Tag.order(:value).ransack(params[:q]).result
        end
        @tags = @tags.page(params[:page]).per(params[:per_page])
        respond_with(@tags)
      end

    end
  end
end
