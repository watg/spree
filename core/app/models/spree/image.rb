module Spree
  class Image < Asset
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    has_attached_file :attachment,
                      styles: { mini: '48x48>', small: '100x100>', product: '240x240>', large: '600x600>' },
                      default_style: :product,
                      url: '/spree/products/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/products/:id/:style/:basename.:extension',
                      # Commented out the colorspace problem until heroku fix their imageMagick issue
                      #convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
                      convert_options: { all: '-strip -auto-orient ' }

    attr_writer :variant_id, :target_id
    before_save :set_viewable

    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions

    process_in_background :attachment

    include Spree::Core::S3Support
    supports_s3 :attachment

    Spree::Image.attachment_definitions[:attachment][:styles] = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles]).symbolize_keys!
    Spree::Image.attachment_definitions[:attachment][:path] = Spree::Config[:attachment_path]
    Spree::Image.attachment_definitions[:attachment][:url] = Spree::Config[:attachment_url]
    Spree::Image.attachment_definitions[:attachment][:default_url] = Spree::Config[:attachment_default_url]
    Spree::Image.attachment_definitions[:attachment][:default_style] = Spree::Config[:attachment_default_style]


    def set_viewable
      if target_id
        v = Variant.find variant_id
        variant_target = v.targets.where(target_id: target_id).first_or_create
        
        self.viewable_id = variant_target.id
        self.viewable_type = 'Spree::VariantTarget'
      else
        self.viewable_id = variant_id
        self.viewable_type = 'Spree::Variant'
      end
    end

    def variant_id
      if @variant_id
        @variant_id
      elsif viewable.kind_of? Spree::Variant
        viewable.id
      elsif viewable.kind_of? Spree::VariantTarget
        viewable.variant_id
      end
    end

    def target_id
      if @target_id 
        @target_id
      elsif viewable.kind_of? Spree::VariantTarget
        viewable.target_id
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
