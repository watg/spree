class VariantPartOptions
  attr_reader :variant

  def initialize(variant, displayable_option_type)
    @variant = variant
    @displayable_option_type = displayable_option_type
  end

  def variant_id
    variant.id
  end

  def presentation
    option_value.presentation
  end

  def type
    option_value.option_type.url_safe_name
  end

  def name
    option_value.name
  end

  def image
    variant.part_image ? variant.part_image.attachment : value_image
  end

  def product_image
    variant_images.any? ? variant_images.first.attachment.url(:mini) : nil
  end

  def value
    option_value.url_safe_name
  end

  def classes
    ["option-value", option_value.url_safe_name, option_value.option_type.url_safe_name].join(" ")
  end

  private

  def option_value
    @option_value ||= variant.option_values.detect do |ov|
      ov.option_type == @displayable_option_type
    end
  end

  def value_image
    option_value.image.url.include?("missing.png") ? nil : option_value.image
  end

  def variant_images
    @variant_images ||= variant.images
  end
end
