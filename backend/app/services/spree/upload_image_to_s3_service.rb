module Spree
  class UploadImageToS3Service < ActiveInteraction::Base

    # Use the format #{bucket}.s3.amazonaws.com to allow for maximum host location flexibility
    DIRECT_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/#{Paperclip::Attachment.default_options[:bucket]}.s3.amazonaws.com\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze

    string  :direct_upload_url
    model :image, class: 'Spree::Image'
    transaction false

    integer :attachment_file_size, default: nil
    string :attachment_file_name, default: nil
    string :attachment_content_type, default: nil

    def execute
      self.direct_upload_url = CGI.unescape(direct_upload_url)
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
      image.update_attributes(inputs.except(:image))
      if !image.persisted?
        errors.add(:image, "Image was not persisted")
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
  end

end
