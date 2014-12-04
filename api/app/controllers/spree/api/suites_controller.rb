module Spree
  module Api
    class SuitesController < Spree::Api::BaseController
      def index
        if params[:id]
          @suite = Spree::Suite.accessible_by(current_ability, :read).where(id: params[:id])
        else
          @suite = Spree::Suite.accessible_by(current_ability, :read).order(:name).ransack(params[:q]).result
        end

        @suite = @suite.page(params[:page]).per(params[:per_page])

        expires_in 15.minutes, :public => true
        headers['Surrogate-Control'] = "max-age=#{15.minutes}"
      end

    end
  end
end
