module Admin 
  class VideosController < ApplicationController
    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Store
    include Spree::Core::ControllerHelpers::Order
    include Rails.application.routes.url_helpers

    layout '/admin/layouts/admin'

    def index
      @videos = Video.all
                     .order('created_at DESC')
    end

    def new
      @video = Video.new
    end

    def create
      @video = CreateVideoService.run(params[:video])
      if @video.valid?
        flash[:success] = "Video created"
        redirect_to '/admin/videos'
      else
        flash[:error] = "Could not create video"
        render :new
      end
    end
  end
end