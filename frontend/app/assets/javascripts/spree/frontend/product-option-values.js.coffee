core.suite.readyVariantOptions = (entity) ->
  master_tree = entity.data('tree')
  option_type_order = entity.data('option-type-order')
  option_values = entity.data('option-values')
  variants_total_on_hand = entity.parents(".wrapper-product-group").data('variants-total-on-hand')

  # Once we have selected all the option values hopefully it will spit out
  # a variant_details object if it does not then something has gone wrong
  variant_details = null
  for option_value in option_values
    variant_details = toggle_option_values(entity, option_value[0], option_value[1], option_value[2], option_type_order, master_tree)
  if variant_details
    update_supplier_details(entity, variant_details['suppliers'])
    set_stock_level(entity, variants_total_on_hand, variant_details['number'])
    set_is_digital(entity, variant_details['is_digital'])
    set_prices(entity, variant_details['id'], variant_details['normal_price'], variant_details['sale_price'], variant_details['in_sale'])
    entity.find('li.tmb-' + variant_details['id']).show()

  # Then get it working with option_value changes
  entity.find(".optional-parts ul input").click (event) ->
    adjust_prices(entity)

  entity.find('.personalisations :checkbox').click (event) ->
    toggle_personalisations(entity, $(this), event)
    adjust_prices(entity)

  # Toggle the personalisation option values
  entity.find('.personalisation-option-value').click (event) ->
    toggle_personalisation_option_value(entity, $(this), event)

  # Friendly flash message in case user tries to checkout without the add-to-cart button
  # being enabled
  entity.find('.add-to-cart-button').click (event) ->
    if $(this).hasClass('disabled')# missing_types.length > 0
      missing_types = []
      for key of option_type_order
        unless entity.find(".variant-option-values.#{key}").hasClass('selected')
         missing_types.push(key)

      # Format the message we return to the user if not enough  of the option
      # types have been selected
      last = missing_types.splice(-1,1)
      message = "Please choose your " + missing_types.join(', ')
      (message = message + " and " ) if missing_types.length > 0
      message = message + last

      entity.find('p.error').remove()
      entity.find('.add-to-cart').prepend($("<p class='error'>#{message}</p>").hide().fadeIn('slow').focus())
      false

  entity.find('.option-value').click (event)->
    event.preventDefault()
    selected_type = $(this).data('type')
    selected_value = $(this).data('value')
    selected_presentation = $(this).data('presentation')
    variant_details = toggle_option_values(entity, selected_type, selected_value, selected_presentation, option_type_order, master_tree)
    if variant_details
      update_url(entity, variant_details['number'])
      update_supplier_details(entity, variant_details['suppliers'])
      set_stock_level(entity, variants_total_on_hand, variant_details['number'])
      set_is_digital(entity, variant_details['is_digital'])
      toggle_images(entity, variant_details['id'])
      set_prices(entity, variant_details['id'], variant_details['normal_price'], variant_details['sale_price'], variant_details['in_sale'])

    # I am so sorry for the following code.
    #
    # If the user has selected a colour but not a size we can't identify the
    # variant but we still want to toggle the images. In that case we walk the
    # options tree starting from the selected colour and keep looking at
    # child nodes until we find a variant. Any variant, we don't care - the all
    # have the same images. For example, given this tree:
    #
    #   {
    #     "colour": {
    #       "red": {
    #         "size": {
    #           "small": {
    #             "variant": {...}
    #           }
    #           "medium": {
    #             "variant": {...}
    #           }
    #         }
    #       }
    #       "blue": {
    #         ...
    #       }
    #     }
    #   }
    #
    # When the users clicks on "red" we want to find any variant under the
    # "red" subtree to toggle the images. So we start at "red" and keep looking
    # at children until we find a key called "variant", then we use it to call
    # toggle_images.
    #
    # I copied/pasted some code from toggle_option_values. You could refactor
    # this into a function but I decided it was less messy to keep all of this
    # horror in a self contained function of shit, rather than smearing it out
    # across other functions.
    else
      node = master_tree
      entity.find('.option-value.selected').each ->
        option_value = $(this)
        type =  option_value.data('type')
        value = option_value.data('value')
        node = node[type][value]
      find_first_variant = (tree) ->
          tree["variant"] || find_first_variant(tree[Object.keys(tree)[0]])
      toggle_images(entity, find_first_variant(node)['id'])

toggle_option_values = (entity, selected_type, selected_value, selected_presentation, option_type_order, master_tree) ->

  # Update the color-text value if type is selected_type is colour
  if (selected_type == 'colour' || selected_type == 'icon-colour')
    selector = "span.color-value.#{selected_type}"
    $(selector).text(selected_presentation)

  # If selected type value is unavailable, then return false
  if entity.find(".option-value.#{selected_type}.#{selected_value}").hasClass('unavailable')
    return false

  # Ensure the option you selected clicked is selected and
  # unselect all the other options at this level
  entity.find(".option-value.#{selected_type}").removeClass('selected')
  entity.find(".option-value.#{selected_type}.#{selected_value}").addClass('selected')
  entity.find(".variant-option-values.#{selected_type}").addClass('selected')

  # Disable the prices by default
  entity.find('.normal-price').addClass('price now unselected').removeClass('was')
  entity.find('.sale-price').addClass('hide').removeClass('selling')

  # Disable the add to cart button
  entity.find('.add-to-cart-button').attr("style", "opacity: 0.5").addClass('disabled')

  # Unselect those downstream
  #next_type = option_type_order[selected_type]
  #if next_type
  #  entity.find(".option-value.#{next_type}").removeClass('selected').addClass('unavailable').addClass('locked')
  #  entity.find(".variant-option-values.#{next_type}").removeClass('selected')

  next_type = option_type_order[selected_type]
  while (next_type)
    entity.find(".option-value.#{next_type}").removeClass('selected').addClass('unavailable').addClass('locked')
    entity.find(".variant-option-values.#{next_type}").removeClass('selected')
    next_type = option_type_order[next_type]

  # For each selected option traverse the tree, until
  # we reach the bottom of the selected nodes, the next set
  # will provide the next choice
  tree = master_tree
  entity.find('.option-value.selected').each ->
    option_value = $(this)
    type =  option_value.data('type')
    value = option_value.data('value')
    tree = tree[type][value]
    if ( (selected_type == type) and (selected_value == value) )
      return false

  # If the node is 'variant' then we have no more options to select
  # so get the pricing info and update the prices
  if 'variant' of tree
   return tree['variant']

  else
    # get the current node of the tree, which will be the type of option
    # value we have to choose a value for, and make only those that
    # should be available, available
    for type,sub_tree of tree
      entity.find(".option-value.#{type}").each ->
        option_value = $(this)
        if option_value.data('value') of sub_tree
          option_value.removeClass('unavailable')
          option_value.removeClass('locked')

  return null

adjust_prices = (entity) ->
  normal_price = entity.find("span.normal-price").data('price')
  sale_price = entity.find("span.sale-price").data('price')
  adjustment = get_adjustment_price(entity)
  entity.find('.normal-price').html( format_price(entity, normal_price + adjustment ) )
  entity.find('.sale-price').html( format_price(entity, sale_price + adjustment ) )

get_adjustment_price = (entity) ->
  optional_part_price = sum_of_optional_part_prices(entity)
  personalisation_price = sum_of_personalisation_prices(entity)
  optional_part_price + personalisation_price

format_price = (entity,pence) ->
  currencySymbol = entity.find(".normal-price").data('currency')
  "#{currencySymbol}#{(pence / 100).toFixed(2)}"

sum_of_personalisation_prices = (entity) ->
  sum = 0
  entity.find(".personalisations input:checked").each ->
    sum = sum + Number $(this).data('price')
  sum

sum_of_optional_part_prices = (entity) ->
  sum = 0
  entity.find(".optional-parts ul input:checked").each ->
    sum = sum + ( Number $(this).data('price') * $(this).data('quantity') )
  sum

set_prices = (entity, variant_id, normal_price, sale_price, in_sale) ->
  entity.find('.variant_id, form[data-form-type="variant"] input[name$="[variant_id]"]').val(variant_id)

  adjustment = get_adjustment_price(entity)

  # Update the data attributes, incase variants have different prices to each other
  entity.find("span.normal-price").data('price', normal_price)
  entity.find("span.sale-price").data('price', sale_price)

  entity.find('.normal-price').html( format_price(entity, normal_price + adjustment ) )
  entity.find('.sale-price').html( format_price(entity, sale_price + adjustment ) )

  entity.find('.normal-price').addClass('selling').removeClass('unselected')
  entity.find('.add-to-cart-button').removeAttr("style").removeClass("disabled")

  if in_sale == true
    entity.find('.normal-price').addClass('was')
    entity.find('.sale-price').addClass('now selling').removeClass('hide')
  else
    entity.find('.normal-price').removeClass('was')
    entity.find('.sale-price').removeClass('now selling').addClass('hide')

set_stock_level = (entity, variants_total_on_hand, variant_number ) ->
  total_on_hand = variants_total_on_hand[variant_number]
  if total_on_hand
    entity.find('.stock-level').css('display', 'initial')
    entity.find('.stock-value').text(total_on_hand + ' left')
  else
    entity.find('.stock-level').css('display', 'none')

set_is_digital = (entity, is_digital) ->
  if is_digital
    entity.find('.digital-available').css('display', 'initial')
  else
    entity.find('.digital-available').css('display', 'none')

update_url = (entity, number) ->
  if number.length > 1

    # Get paths
    path = core.getUrlPathAsArray();

    # If we have a query string, ensure we append it to the updated URL
    query = ''
    if window.location.search
      query = window.location.search;

    # Update the URL
    History.replaceState(null, null, '/' + path[1] + '/' + path[2] + '/' + path[3] + '/' + number + query);

update_supplier_details = (entity, suppliers) ->
  names = []
  profiles = []

  # Loop through suppliers
  for index, supplier of suppliers
    for index, items of supplier
      names.push(items.nickname)
      if items.nickname != null
        profiles.push('<strong>' + items.nickname + '</strong>: ' + items.profile)

  # Prep names for output...
  if names.length > 1
    names = names.slice(0, names.length - 1).join(', ') + " and " + names.slice(-1)
  else
    names = 'WATG'
  names = ' #madeunique <span>by ' + names + '</span>'

  # Prep profiles for output...
  if profiles.length > 1
    profiles = profiles.join('<br/><br/>')

  # Update heading and reveal panel
  heading = entity.find('.suppliers')
  img = heading.find('img')
  heading.empty().append(img).append(names)
  heading.next().html(profiles)

# Modify the images based on the selected variant
toggle_images = (entity, variant_id) ->

  all_thumbs = entity.find('li.vtmb')
  all_thumbs.hide()
  variant_thumbs = entity.find('li.tmb-' + variant_id)
  variant_thumbs.show()

  thumb = entity.find("ul.thumbnails li.tmb-" + variant_id + ":first").eq(0)
  if (thumb.length == 0)
    thumb = entity.find('ul.thumbnails li').eq(0)
  change_main_image(entity, thumb)

change_main_image = (entity, thumb) ->
  newImg = thumb.find('a').attr('href')
  entity.find('ul.thumbnails li').removeClass('selected')
  thumb.addClass('selected')
  entity.find('.main-image img').attr('src', newImg)
  entity.find('.main-image img').attr('data-zoomable', newImg.replace('product', 'original')) # Update zoomable
  entity.find('.main-image a').attr('href', newImg)
  entity.find(".main-image").data('selectedThumb', newImg)
  #$("#main-image").data('selectedThumbId', thumb.attr('id'))

toggle_personalisation_option_value = (entity, element, event) ->
  event.preventDefault()
  personalisation = element.parents('.personalisation')

  selected_type = element.data('type')
  selected_value = element.data('value')
  selected_presentation = element.data('presentation')

  # Update the color-text value if type is selected_type is colour
  if selected_type == 'colour'
    personalisation.find("span.personalisation-color-value").text(selected_presentation)
    personalisation.find('.hidden.personalisation-colour').val(element.data('id'))

  # If selected type value is unavailable, then return false
  if personalisation.find(".personalisation-option-value.#{selected_type}.#{selected_value}").hasClass('unavailable')
    return false

  # Ensure the option you selected clicked is selected and
  # unselect all the other options at this level
  personalisation.find(".personalisation-option-value.#{selected_type}").removeClass('selected')
  personalisation.find(".personalisation-option-value.#{selected_type}.#{selected_value}").addClass('selected')

toggle_personalisations = (entity, checkbox, event) ->
  personalisation = checkbox.parents('.personalisation')
  personalisation_id = checkbox.val()
  thumbs = entity.find("ul.thumbnails li.tmb-personalisation-" + personalisation_id)

  if checkbox.is(':checked')
    if thumbs.length > 0
      thumbs.show()
      thumb = thumbs.first()
      change_main_image(entity, thumb)
    personalisation.find('.personalisation-options').show()
    personalisation.find('.personalisation-option-values').show()

  else
    if thumbs.length > 0
      thumbs.hide()
      # When you deselect the peronalisation options, select
      # the first visible image from the remaining thumbnails
      thumb = entity.find("ul.thumbnails li.vtmb:visible").first()
      change_main_image(entity, thumb)
    personalisation.find('.personalisation-options').hide()
    personalisation.find('.personalisation-option-values').hide()



