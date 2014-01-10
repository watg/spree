module Spree
  module Api
    class TargetsController < Spree::Api::BaseController

      def index
        if params[:ids]
          @targets = Spree::Target.where(id: params[:ids].split(','))
        else
          @targets = Spree::Target.order(:name).ransack(params[:q]).result
        end
        @targets = @targets.page(params[:page]).per(params[:per_page])
        respond_with(@targets)
      end

    end
  end
end
