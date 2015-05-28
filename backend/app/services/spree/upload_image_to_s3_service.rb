module Spree
  class UploadImageToS3Service < ActiveInteraction::Base

    # Use the format #{bucket}.s3.amazonaws.com to allow for maximum host location flexibility
    DIRECT_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/#{Paperclip::Attachment.default_options[:bucket]}.s3.amazonaws.com\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze

    interface :image, methods: %i[attachment processed update_attributes persisted? attachment_file_name attachment_file_size attachment_content_type processed?]
    transaction false

    hash :params do
      integer :filesize, default: nil
      string :filename, default: nil
      string :filetype, default: nil
      hash :image do
        string :direct_upload_url
      end
    end


    def execute
      unless DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
        errors.add(:direct_upload_url, "Url not correctly formatted")
        return
      end

      if image.attachment.exists?
        image.attachment.destroy
      end

      # call to s3 to obtain details for the image (largely unneeded)
      # set_attachment_attributes_from_s3
      image.processed = false
      image.attachment_file_size = params[:filesize]
      image.attachment_file_name = params[:filename]
      image.attachment_content_type = params[:filetype]
      image.direct_upload_url = direct_upload_url
      unless image.save
        errors.add(:image, "Image was not saved")
        return
      end

      job = Spree::UploadImage.new(image, DIRECT_UPLOAD_URL_FORMAT)
      ::Delayed::Job.enqueue(job, queue: 'images')
      image
    end

    # Set attachment attributes from the direct upload
    # @note Retry logic handles S3 "eventual consistency" lag.
    def set_attachment_attributes_from_s3
      tries ||= 5

      s3 = AWS::S3.new
      direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
      direct_upload_head = s3.buckets[Rails.configuration.aws[:bucket]].objects[direct_upload_url_data[:path]].head

      image.attachment_file_name     = direct_upload_url_data[:filename]
      image.attachment_file_size     = direct_upload_head.content_length
      image.attachment_content_type  = direct_upload_head.content_type
      # attachment_updated_at    = direct_upload_head.last_modified
    rescue AWS::S3::Errors::NoSuchKey => e
      tries -= 1
      if tries > 0
        sleep(3)
        retry
      else
        false
      end
    end

    def direct_upload_url
      CGI.unescape(params[:image][:direct_upload_url])
    end
  end
end
