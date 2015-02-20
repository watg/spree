module Spree
  UploadImage = Struct.new(:image, :direct_upload_url_format) do
    def perform
      direct_upload_url_data = direct_upload_url_format.match(image.direct_upload_url)
      s3 = AWS::S3.new

      begin
        image.attachment = URI.parse(URI.escape(image.direct_upload_url))
      rescue OpenURI::HTTPError => error
        Helpers::AirbrakeNotifier.notify(error.message)
        return
      end

      image.find_dimensions
      image.save!

      image.update_column(:processed, true)

      s3.buckets[Rails.configuration.aws[:bucket]].objects[direct_upload_url_data[:path]].delete
    end
  end
end
