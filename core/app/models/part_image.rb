class PartImage < ActiveRecord::Base
  include ::Images::S3Callbacks

  STANDARD_SWATCH = "50x50>"
  LARGE_SWATCH = "100X100>"

  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant"
  validate :no_attachment_errors
  has_attached_file :attachment,
                    styles: {
                      small: STANDARD_SWATCH,
                      large: LARGE_SWATCH
                    },
                    default_style: :small,
                    # Commented out the colorspace problem until heroku fix their imageMagick issue
                    # convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
                    convert_options: {
                      all: "-strip -auto-orient"
                    }

  validates_attachment :attachment,
                       presence: true,
                       content_type: { content_type: %w(image/jpeg image/jpg image/png image/gif) }

  # save the w,h of the original image (from which others can be calculated)
  # we need to look at the write-queue for images which have not been saved yet
  after_post_process :find_dimensions
end
