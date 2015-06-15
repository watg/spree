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
      img = part_image.processed? ? part_image.attachment.url(:small) : part_image.direct_upload_url
      image_tag(img, style: "max-width: 100px")
    end

    private

    def product_attachment
      part_image.attachment.url(:product)
    end
  end
end
