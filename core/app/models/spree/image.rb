module Spree
  class Image < Asset
    acts_as_paranoid
    
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    has_attached_file :attachment,
                      styles: {
                        :mini    => '66x84>',    # thumbs under image (product * 0.14),
                        :listing => '150x192>',  # listing in basket (product * 0.32),
                        :small   => '310x396>',  # images on category view (product * 0.66),
                        :product => '470x600>',  # product page full product image
                        :large   => '940x1200>'  # light box image
                      },
                      default_style: :product,
                      # Commented out the colorspace problem until heroku fix their imageMagick issue
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions

    def variant_id
      if viewable_type == "Spree::Variant"
        return viewable_id
      elsif viewable_type == "Spree::VariantTarget"
        return viewable.variant_id
      end
    end

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
        # uncomment this to get rid of the less-than-useful interrim messages
        # errors.clear
        errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
        false
      end
    end

  end
end
