class Spree::ProductDecorator < Draper::Decorator
  delegate_all
  
  def memoized_variant_images
    @_variant_images ||= object.images_for(context[:target])
  end

  def memoized_images
    @_images ||= object.images
  end

  def memoized_personalisation_images
    @_memoized_personalisation_images ||= object.personalisation_images
  end

  def memoized_has_variants?
    @_has_variant ||= object.has_variants?
  end

  def memoized_variants_and_option_values
    @_variants_and_option_values ||= object.variants_and_option_values(context[:current_currency])
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
  
  def memoized_gang_member_visible?
    @_gang_member_visible ||= object.memoized_gang_member.try(:visible?)
  end

  def memoized_gang_member_avatar_url
    @_gang_member_avatart_url ||= object.memoized_gang_member.avatar.url(:avatar)
  end

  def memoized_gang_member_nickname
    @_gang_member_nickname ||= object.memoized_gang_member.nickname
  end

  def memoized_gang_member_profile
    @_gang_member_profile ||= object.memoized_gang_member.profile
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

  def memoized_variant_options_tree
    @_variant_options_tree ||= {}
    @_variant_options_tree[[context[:target],current_currency]] ||= object.variant_options_tree_for(context[:target],current_currency)
  end

  def memoized_option_type_order
    @_option_type_order ||= object.option_type_order 
  end

  def memoized_targeted_grouped_option_values
    @_memoized_targeted_grouped_option_values_for ||= object.grouped_option_values_for(context[:target])
  end
  
  def item_quantity(obj)
    obj.respond_to?(:count_part) ? obj.count_part : 1
  end
  
  def price_in_pence(obj,currency)
    method = (obj.is_master ? :price_in : :kit_price_in)
    price = obj.send(method, currency).price 
    ( price * 100 * item_quantity(obj) ).to_i
  end

  
end
