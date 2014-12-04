module Spree
  module Admin
    class SuiteTabsController < ResourceController

      belongs_to 'spree/suite', :find_by => :permalink

      def s3_callback
        image = SuiteTabImage.where(viewable: @suite_tab).first_or_create
        @outcome = UploadImageToS3Service.run(
          image: image,
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url]
        )

        render 'spree/admin/suites/s3_callback'
      end

    end
  end
end
