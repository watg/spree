module Spree
  module Admin
    class SuiteTabsController < ResourceController

      belongs_to 'spree/suite', :find_by => :permalink

      def s3_callback
        image = SuiteTabImage.where(viewable: @suite_tab).first_or_create
        @outcome = UploadImageToS3Service.run(
          image: image,
          params: params
        )

        render 'spree/admin/suites/s3_callback'
      end

    end
  end
end
