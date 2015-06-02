module Admin
  # Presents Part Image
  class PartImagePresenter < Spree::BasePresenter
    presents :part_image

    delegate :id, to: :part_image
    delegate :link_to, :image_tag, to: :template

    def self.model_name
      ::PartImage.model_name
    end

    def image_url
      if part_image.processed?
        link_to image_tag(part_image.attachment.url(:small),
                          style: "max-width: 100px"), product_attachment
      else
        link_to image_tag(part_image.direct_upload_url,
                          style: "max-width: 100px"), product_attachment
      end
    end

    private

    def product_attachment
      part_image.attachment.url(:product)
    end
  end
end
