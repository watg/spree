module Spree
  module Admin
    class AssemblyDefinitionImagesController < ResourceController
      before_filter :load_data

      create.before :set_viewable
      update.before :set_viewable

      def s3_callback
        callback_params = {
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url],
        }
        image = AssemblyDefinitionImage.new(viewable: @assembly_definition)
        @outcome = UploadImageToS3Service.run(callback_params, image: image)
      end

      def location_after_save
        edit_admin_assembly_definitions_path(@assembly_definition)
      end

      def location_after_destroy
        edit_admin_assembly_definitions_path(@assembly_definition)
      end


      def collection_url(opts={})
        spree.admin_assembly_definitions_url(opts)
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
