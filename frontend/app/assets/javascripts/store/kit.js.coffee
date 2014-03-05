core.productGroup.readyKitVariantOptions = (entity) ->

  entity.find('.option-value').click (event)->
    event.preventDefault()
    option_value = $(this)
    selected_type = option_value.data('type')
    selected_value = option_value.data('value')
    selected_presentation = option_value.data('presentation')

    option_values = option_value.closest('.variant-option-values')
    product_variants = option_values.closest('.product-variants')
    tree = product_variants.data('tree')

    variant = tree[selected_type][selected_value]['variant']

    # If selected type value is unavailable, then return false
    if option_value.hasClass('unavailable')
      return false

    # Ensure the option you selected clicked is selected and
    # unselect all the other options at this level
    option_values.find('.option-value').removeClass('selected')
    option_value.closest('.variant-options').addClass('selected')
    option_value.addClass('selected')

    # Set the option value text
    option_values.prev('.variant-option-type').find('span').text(selected_presentation)

    # Set the variant_id
    product_variants.find('.selected-parts').val(variant['id'])

    entity.find(".prices").trigger('update')
    entity.find(".add-to-cart-button").trigger('update')

    product_variants.find(".product-part-image").show()
    product_variants.find(".product-part-image img").attr('src', variant['image_url'])


###### High level #################################################################################################################

 # entity.find('.option-value').click (event)->
 #   entity.find(".main-image").trigger('update_part_images')


  entity.find(".optional-parts input").click (event) ->
    entity.find(".price").trigger('recalculate')
    image = $(this).closest('.optional-part').find('.product-part-image')
    if $(this).is(':checked')
      image.show()
    else
      image.hide()

###### Image  #################################################################################################################
#
 # entity.find(".main-image").on('update_part_images',( ->
 #   $(this).html( format_price($(this).data('currency'), $(this).data('price') + adjustment ) )
 # ))


###### Prices #################################################################################################################
#
  entity.find(".prices").on('update',( ->
    if entity.find('.variant-options:not(.selected)').length > 0
      $(this).find('.normal-price').addClass('price now unselected').removeClass('was')
      $(this).find('.sale-price').addClass('hide').removeClass('selling')
    else
      $(this).find('.normal-price').addClass('selling').removeClass('unselected')
  ))

  entity.find(".price").on('recalculate',( ->
    adjustment = sum_of_optional_part_prices(entity)
    $(this).html( format_price($(this).data('currency'), $(this).data('price') + adjustment ) )
  ))

  format_price = (currencySymbol,pence) ->
    "#{currencySymbol}#{(pence / 100).toFixed(2)}"

  sum_of_optional_part_prices = (entity) ->
    sum = 0
    entity.find(".optional-parts input:checked").each ->
      sum = sum + Number $(this).data('price')
    sum

#######################################################################################################################

# Friendly flash message in case user tries to checkout without the add-to-cart button
  # being enabled
  entity.find(".add-to-cart-button").on('update',( ->
    if entity.find('.variant-options:not(.selected)').length > 0
      $(this).attr("style", "opacity: 0.5").addClass('disabled')
    else
      $(this).removeAttr("style").removeClass("disabled")
  ))

  entity.find('.add-to-cart-button').click (event) -> 
    if $(this).hasClass('disabled')

      missing_types = []
      entity.find('.variant-options:not(.selected)').each ->
        missing_types.push $(this).data('type')

      # Format the message we return to the user if not enough of the option
      # types have been selected
      last = missing_types.splice(-1,1)
      message = "Please choose your " + missing_types.join(', ')
      (message = message + " and " ) if missing_types.length > 0
      message = message + last

      entity.find('p.error').remove()
      entity.find('.add-to-cart').prepend($("<p class='error'>#{message}!</p>").hide().fadeIn('slow').focus())
      false


# Functionise it all
# pass a uncomplicated hash instead of the nested rubbish
# Disable cart button and price
