module Spree
  module Admin
    class SuitesController < ResourceController

      def s3_callback
        image = SuiteImage.where(viewable: @suite).first_or_create
        @outcome = UploadImageToS3Service.run(
          image: image,
          params: params
        )
      end

      def update
        outcome = SuiteUpdateService.run(suite: @suite, params: suite_params)
        if outcome.valid?
          flash[:success] = flash_message_for(outcome, :successfully_updated)
          respond_with(outcome.result) do |format|
            format.html { redirect_to location_after_save }
            format.js   { render :layout => false }
          end
        else
          respond_with(@suite)
        end
      end

      protected
      def suite_params
        params.require(:suite).permit!
      end

      def find_resource
        Suite.find_by(permalink: params[:id])
      end

      def location_after_save
        edit_admin_suite_url(@suite)
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        params[:q][:s] ||= "name asc"
        @collection = super
        # @search needs to be defined as this is passed to search_form_for
        @search = @collection.ransack(params[:q])
        @collection = @search.result.page(params[:page]).per( 15 )
        @collection
      end

    end
  end
end
