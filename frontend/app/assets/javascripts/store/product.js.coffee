core.productGroup.readyVariantOptions = (entity) ->

# Hack to get the fancybox working, this is really wrong!!! needs fixing
  $("body").trigger("thumbs_updated")

  master_tree = entity.data('tree')
  option_type_order = entity.data('option-type-order')
  option_values = entity.data('option-values')

  # Once we have selected all the option values hopefully it will spit out
  # a variant_details object if it does not then something has gone wrong
  variant_details = null
  for option_value in option_values
    variant_details = toggle_option_values(entity, option_value[0], option_value[1], option_value[2], option_type_order, master_tree)
  if variant_details
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
    console.log($(this).attr("disabled"))
    if $(this).hasClass('disabled')
      $('<p class="error"><strong>Please select COLOUR and SIZE</p>').hide().insertBefore('.product-variants').fadeIn('slow').delay(1500).fadeOut('slow')
      false

  entity.find('.option-value').click (event)->
    event.preventDefault()
    selected_type = $(this).data('type')
    selected_value = $(this).data('value')
    selected_presentation = $(this).data('presentation')
    variant_details = toggle_option_values(entity, selected_type, selected_value, selected_presentation, option_type_order, master_tree)
    if variant_details
      toggle_images(entity, variant_details['id'])
      set_prices(entity, variant_details['id'], variant_details['normal_price'], variant_details['sale_price'], variant_details['in_sale'])

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

  # Disable the prices by default
  entity.find('.normal-price').addClass('price now unselected').removeClass('was')
  entity.find('.sale-price').addClass('hide').removeClass('selling')

  # Disable the add to cart button
  entity.find('.add-to-cart-button').attr("style", "opacity: 0.5").addClass('disabled')

  # Unselect those downstream
  #  next_type = entity.find(".variant-options.#{selected_type}").data('next_type')
  next_type = option_type_order[selected_type] 
  if next_type
    entity.find(".option-value.#{next_type}").removeClass('selected')

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
        else
          option_value.addClass('unavailable')
          option_value.addClass('locked')

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
    sum = sum + Number $(this).data('price')
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


# Modify the images based on the selected variant
toggle_images = (entity, variant_id) ->
  
  all_thumbs = entity.find('li.vtmb')
  all_thumbs.hide()
  variant_thumbs = entity.find('li.tmb-' + variant_id)
  variant_thumbs.show()

  # Hack - this allows us to ensure that only the variant images
  # make it to the image gallery
  all_thumbs.find('a').removeClass('fancybox')
  variant_thumbs.find('a').addClass('fancybox')

  thumb = entity.find("ul.thumbnails li.tmb-" + variant_id + ":first").eq(0)
  if (thumb.length == 0)
    thumb = entity.find('ul.thumbnails li').eq(0)
  change_main_image(entity, thumb)

change_main_image = (entity, thumb) ->
  newImg = thumb.find('a').attr('href')
  entity.find('ul.thumbnails li').removeClass('selected')
  thumb.addClass('selected')
  entity.find('.main-image img').attr('src', newImg)
  entity.find('.main-image a').attr('href', newImg)
  entity.find(".main-image").data('selectedThumb', newImg)
  #$("#main-image").data('selectedThumbId', thumb.attr('id'))

toggle_personalisation_option_value = (entity, element, event) ->
  event.preventDefault()
  selected_type = element.data('type')
  selected_value = element.data('value')
  selected_presentation = element.data('presentation')

  # Update the color-text value if type is selected_type is colour
  if selected_type == 'colour'
    $("span.personalisation-color-value").text(selected_presentation)
    entity.find('.hidden.personalisation-colour').val(element.data('id'))

  # If selected type value is unavailable, then return false
  if entity.find(".personalisation-option-value.#{selected_type}.#{selected_value}").hasClass('unavailable')
    return false

  # Ensure the option you selected clicked is selected and
  # unselect all the other options at this level
  entity.find(".personalisation-option-value.#{selected_type}").removeClass('selected')
  entity.find(".personalisation-option-value.#{selected_type}.#{selected_value}").addClass('selected')

toggle_personalisations = (entity, e, event) ->
  personalisation_id = e.val()
  thumbs = entity.find("ul.thumbnails li.tmb-personalisation-" + personalisation_id)

  if e.is(':checked')
    if thumbs.length > 0
      thumbs.show()
      thumb = thumbs.first()
      change_main_image(entity, thumb)
    entity.find('.personalisation-options').show()
    entity.find('.personalisation-option-values').show()

  else
    if thumbs.length > 0
      thumbs.hide()
      # When you deselect the peronalisation options, select
      # the first visible image from the remaining thumbnails
      thumb = entity.find("ul.thumbnails li.vtmb:visible").first()
      change_main_image(entity, thumb)
    entity.find('.personalisation-options').hide()
    entity.find('.personalisation-option-values').hide()



