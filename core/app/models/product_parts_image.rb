class ProductPartsImage < ActiveRecord::Base
  include ::Images::S3Callbacks
  acts_as_paranoid

  # TODO: dry this up with images
  validate :no_attachment_errors

  belongs_to :target, class_name: "Spree::Target", inverse_of: :images

  has_attached_file :attachment,
                    styles: {
                      mini: "66x84>",    # thumbs under image (product * 0.14),
                      listing: "150x192>",  # listing in basket (product * 0.32),
                      small: "310x396>",  # images on category view (product * 0.66),
                      product: "470x600>",  # product page full product image
                      large: "940x1200>"  # light box image
                    },
                    default_style: :product,
                    # Commented out the colorspace problem until heroku fix their imageMagick issue
                    # convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
                    convert_options: {
                      all: "-strip -auto-orient",
                      product: "-quality 80",
                      large: "-quality 80"
                    }

  validates_attachment :attachment,
                       presence: true,
                       content_type: { content_type: %w(image/jpeg image/jpg image/png image/gif) }

  # save the w,h of the original image (from which others can be calculated)
  # we need to look at the write-queue for images which have not been saved yet
  after_post_process :find_dimensions

  def self.with_target(target)
    target_id = target ? target.id : nil
    where(target_id: [nil, target_id])
  end
end
