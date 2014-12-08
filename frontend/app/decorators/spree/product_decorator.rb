class Spree::ProductDecorator < Draper::Decorator
  delegate_all

  def variant_options
    @variant_options ||= Spree::VariantOptions.new(variants, currency)
  end

  def target
    context[:target]
  end

  def memoized_variant_images
    @_variant_images ||= object.variant_images_for(context[:target])
  end

  def memoized_images
    @_images ||= object.images_for(context[:target])
  end

  def memoized_personalisation_images
    @_memoized_personalisation_images ||= object.personalisation_images
  end

  def memoized_has_variants?
    @_has_variant ||= object.has_variants?
  end
  def current_currency
    @_current_currency ||= context[:current_currency] || Spree::Config[:currency]
  end

  def memoized_has_personalisation?
    @_has_personalisation ||= !object.personalisations.blank?
  end

  def memoized_personalisations
    @_memoized_personalisations ||= object.personalisations
  end
  
  def first_image
    images = context[:target].nil? ? object.variant_images : object.images_for(context[:target])
    images.first if images.any?
  end

  def description
    description = object.description_for(context[:target]) || ''
    description = description.gsub(/(.*?)\r?\n\r?\n/m, '\1<br><br>')
    description.gsub(/_/, '').gsub(/-/, '&ndash;').html_safe
  end

  def first_image_url(style = :small)
    if first_image.present?
      first_image.attachment.url(style)
    else
      h.image_path('product-group/placeholder-470x600.gif')
    end
  end

  def first_image_alt
    first_image.present? ? first_image.alt : 'No image'
  end

  ################## Done #############
  def memoized_variant_options_tree
    @variant_options_tree ||= variant_options.tree
  end

  def memoized_option_type_order
    @option_type_order ||= variant_options.option_type_order
  end

  def memoized_targeted_grouped_option_values
    @targeted_grouped_option_values ||= variant_options.grouped_option_values_in_stock
  end

  def option_types_and_values(variant)
    variant_options.option_types_and_values_for(variant)
  end
  ##################### Next #############

  
  def item_quantity(obj)
    obj.respond_to?(:count_part) ? obj.count_part : 1
  end
  
  def price_in_pence(obj,currency)
    method = (obj.is_master ? :price_in : :kit_price_in)
    _price = obj.send(method, currency).price
    ( _price * 100 * item_quantity(obj) ).to_i
  end

  def price
    object.price_normal_in(currency)
  end

  
end
