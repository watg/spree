class PartImage < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant"
  validate :no_attachment_errors

  has_attached_file :attachment,
                    styles: {
                      :small => "50x50>",    # standard swatch size,
                      :large => "100X100>"
                    },
                    default_style: :small,
                    # Commented out the colorspace problem until heroku fix their imageMagick issue
                    # convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
                    convert_options: {
                      all: '-strip -auto-orient'
                    }

  validates_attachment :attachment,
    :presence => true,
    :content_type => { :content_type => %w(image/jpeg image/jpg image/png image/gif) }

  # save the w,h of the original image (from which others can be calculated)
  # we need to look at the write-queue for images which have not been saved yet
  after_post_process :find_dimensions

  #used by admin products autocomplete
  def mini_url
    attachment.url(:mini, false)
  end

  def find_dimensions
    temporary = attachment.queued_for_write[:original]
    filename = temporary.path unless temporary.nil?
    filename = attachment.path if filename.blank?
    geometry = Paperclip::Geometry.from_file(filename)
    self.attachment_width  = geometry.width
    self.attachment_height = geometry.height
  end

  # if there are errors from the plugin, then add a more meaningful message
  def no_attachment_errors
    unless attachment.errors.empty?
      # uncomment this to get rid of the less-than-useful interim messages
      # errors.clear
      errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
      false
    end
  end

end
