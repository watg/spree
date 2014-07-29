module Spree
  module Admin
    class AssemblyDefinitionImagesController < ResourceController
      before_filter :load_data

      update.before :set_viewable

      def s3_callback
        image = AssemblyDefinitionImage.new(viewable: @assembly_definition)
        @outcome = UploadImageToS3Service.run(
          image: image,
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url]
        )
      end

      private

        def load_data
          @assembly_definition = AssemblyDefinition.find(params[:assembly_definition_id])
        end

        def set_viewable
          @image.viewable_type = 'Spree::AssemblyDefinition'
          @image.viewable_id = params[:image][:viewable_id]
        end

    end
  end
end
