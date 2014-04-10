Spree.ready ($) ->

  return false unless $("body").hasClass("product-details") # Die if incorrect product page

  # Hack to get the fancybox working, this is really wrong!!! needs fixing
  $("body").trigger("thumbs_updated")

  master_tree =  $('#product-variants').data('tree')
  # A hash to allow us to walk downsream from each of the option types
  # e.g. Colour -> Size -> nil
  option_type_order =  $('#product-variants').data('option_type_order')

  # Then get it working with option_value changes
  $("#optional-parts ul input").click (event) ->
    adjust_prices()
    
  $('.personalisations :checkbox').click (event) ->
    toggle_personalisations($(this), event)
    adjust_prices()

  # Toggle the personalisation option values
  $('.personalisation-option-value').click (event) ->
    toggle_personalisation_option_value($(this),event)

  $('.option-value').click (event)->
    event.preventDefault()

    selected_type = $(this).data('type')
    selected_value = $(this).data('value')
    selected_presentation = $(this).data('presentation')

    # Update the color-text value if type is selected_type is colour
    if selected_type == 'colour'
      $("span.color-value").text(selected_presentation)

    # If selected type value is unavailable, then return false
    if $(".option-value.#{selected_type}.#{selected_value}").hasClass('unavailable')
      return false

    # Ensure the option you selected clicked is selected and
    # unselect all the other options at this level
    $(".option-value.#{selected_type}").removeClass('selected')
    $(".option-value.#{selected_type}.#{selected_value}").addClass('selected')

    # Disable the prices by default
    $('#normal-price').addClass('price now unselected').removeClass('was')
    $('#sale-price').addClass('hide').removeClass('selling')

    # Disable the add to cart button
    $('#add-to-cart-button').attr("disabled","disabled").attr("style", "opacity: 0.5")

    # Unselect those downstream
    #  next_type = $(".variant-options.#{selected_type}").data('next_type')
    next_type = option_type_order[selected_type] 
    if next_type
      $(".option-value.#{next_type}").removeClass('selected')

    # For each selected option traverse the tree, until 
    # we reach the bottom of the selected nodes, the next set
    # will provide the next choice
    tree = master_tree
    $('.option-value.selected').each ->
      option_value = $(this)
      type =  option_value.data('type')
      value = option_value.data('value')
      tree = tree[type][value]
      if ( (selected_type == type) and (selected_value == value) )
        return false

    # If the node is 'variant' then we have no more options to select
    # so get the pricing info and update the prices
    if 'variant' of tree
      toggle_images( tree )
      set_prices( tree )

    else
      # get the current node of the tree, which will be the type of option
      # value we have to choose a value for, and make only those that 
      # should be available, available
      for type,sub_tree of tree
        $(".option-value.#{type}").each ->
          option_value = $(this)
          if option_value.data('value') of sub_tree
            option_value.removeClass('unavailable')
            option_value.removeClass('locked')
          else
            option_value.addClass('unavailable')
            option_value.addClass('locked')

adjust_prices = () ->
  normal_price = $("span#normal-price").data('price')
  sale_price = $("span#sale-price").data('price')
  adjustment = get_adjustment_price()
  $('#normal-price').html( format_price( normal_price + adjustment ) )
  $('#sale-price').html( format_price( sale_price + adjustment ) )

get_adjustment_price = () ->
  optional_part_price = sum_of_optional_part_prices()
  personalisation_price = sum_of_personalisation_prices()
  optional_part_price + personalisation_price

format_price = (pence) ->
  currencySymbol = $("#normal-price").data('currency')
  "#{currencySymbol}#{(pence / 100).toFixed(2)}"


sum_of_personalisation_prices = () ->
  sum = 0
  $(".personalisations input:checked").each ->
    sum = sum + Number $(this).data('price')
  sum

sum_of_optional_part_prices = () ->
  sum = 0
  $("#optional-parts ul input:checked").each ->
    sum = sum + Number $(this).data('price')
  sum

set_prices = (tree) ->
  $('#variant_id, form[data-form-type="variant"] input[name$="[variant_id]"]').val(tree['variant']['id'])

  adjustment = get_adjustment_price()
  normal_price = tree['variant']['normal_price']
  sale_price = tree['variant']['sale_price']

  # Update the data attributes, incase variants have different prices to each other
  $("span#normal-price").data('price', normal_price)
  $("span#sale-price").data('price', sale_price)

  $('#normal-price').html( format_price( normal_price + adjustment ) )
  $('#sale-price').html( format_price( sale_price + adjustment ) )

  $('#normal-price').addClass('selling').removeClass('unselected')
  $('#add-to-cart-button').removeAttr("disabled").removeAttr("style")

  if tree['variant']['in_sale'] == true
    $('#normal-price').addClass('was')
    $('#sale-price').addClass('now selling').removeClass('hide')
  else
    $('#normal-price').removeClass('was')
    $('#sale-price').removeClass('now selling').addClass('hide')


# Modify the images based on the selected variant
toggle_images = (tree) ->
  variant_id = tree['variant']['id']
  $('li.vtmb').hide()
  #$('li.tmb-all').hide()
  $('li.tmb-' + variant_id).show()
  # SelectedThumbId is not currently available from the data
  # hence it has been commented out
  #currentThumb = $('#' + $("#main-image").data('selectedThumbId'))
  # if currently selected thumb does not belong to current variant, nor to common images,
  # hide it and select the first available thumb instead.
  #if(!currentThumb.hasClass('tmb-' + variant_id)) 
  thumb = $($("ul.thumbnails li.tmb-" + variant_id + ":first").eq(0))
  if (thumb.length == 0)
    thumb = $($('ul.thumbnails li:visible').eq(0))
  change_main_image(thumb)

change_main_image = (thumb) ->
  newImg = thumb.find('a').attr('href')
  $('ul.thumbnails li').removeClass('selected')
  thumb.addClass('selected')
  $('#main-image img').attr('src', newImg)
  $('#main-image a').attr('href', newImg)
  $("#main-image").data('selectedThumb', newImg)
  #$("#main-image").data('selectedThumbId', thumb.attr('id'))

toggle_personalisation_option_value = (element,event) ->
  event.preventDefault()
  selected_type = element.data('type')
  selected_value = element.data('value')
  selected_presentation = element.data('presentation')

  # Update the color-text value if type is selected_type is colour
  if selected_type == 'colour'
    $("span.personalisation-color-value").text(selected_presentation)
    $('.hidden.personalisation-colour').val(element.data('id'))

  # If selected type value is unavailable, then return false
  if $(".personalisation-option-value.#{selected_type}.#{selected_value}").hasClass('unavailable')
    return false

  # Ensure the option you selected clicked is selected and
  # unselect all the other options at this level
  $(".personalisation-option-value.#{selected_type}").removeClass('selected')
  $(".personalisation-option-value.#{selected_type}.#{selected_value}").addClass('selected')

toggle_personalisations = (e,event) ->

  personalisation_id = e.val()
  thumbs = $("ul.thumbnails li.tmb-personalisation-" + personalisation_id)

  if e.is(':checked')
    thumbs.show()
    thumb = thumbs.first()
    change_main_image(thumb)
    $('.personalisation-options').show()
    $('.personalisation-option-values').show()

  else
    thumbs.hide()
    # When you deselect the peronalisation options, select
    # the first visible image from the remaining thumbnails
    thumb = $("ul.thumbnails li.vtmb:visible").first()
    change_main_image(thumb)
    $('.personalisation-options').hide()
    $('.personalisation-option-values').hide()



