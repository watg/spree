core.productGroup.readyKitVariantOptions = (entity) ->

  entity.find('.option-value').click (event)->
    event.preventDefault()
    option_value = $(this)
    selected_presentation = option_value.data('presentation')

    option_values = option_value.closest('.variant-option-values')
    product_variants = option_values.closest('.product-variants')

    # If selected type value is unavailable, then return false
    if option_value.hasClass('unavailable')
      return false

    # Show thumbs and change main image
    thumbs = entity.find('ul.thumbnails li.tmb-assembly-definition')
    thumbs.show()
    thumb_href = thumbs.first().find('a').attr('href')
    main_image = entity.find('.main-image')
    main_image.find('img').attr('src', thumb_href)
    main_image.find('a').attr('href', thumb_href)

    # Ensure the option you selected clicked is selected and
    # unselect all the other options at this level
    option_values.find('.option-value').removeClass('selected')
    option_value.closest('.variant-options').addClass('selected')
    option_value.addClass('selected')

    # Set the option value text
    product_variants.find('span').eq(0).text(selected_presentation)

    # Walk the tree to get a variant id
    tree = product_variants.data('tree')
    selected_option_values = product_variants.find('.option-value.selected').each ->
      tree = tree[$(this).data('type')][$(this).data('value')]

    if 'variant' of tree
      variant = tree['variant']

      # Set the variant_id
      product_variants.find('.selected-parts').val(variant['id'])

      # Set the adjustments on the parts
      product_variants.data('adjustment', variant['part_price'])

      if variant['image_url']
        $('.assembly-images li').eq(product_variants.index()).show().css('background-image', 'url(' + variant['image_url'] + ')')

    entity.find(".price").trigger('recalculate')
    entity.find(".prices").trigger('update')
    entity.find(".add-to-cart-button").trigger('update')

    # Adjust list heights
    core.productGroup.setAssemblyListHeights()

###### Prices #########################################################################################################

  entity.find(".prices").on('update',( ->
    if entity.find('.variant-options.required:not(.selected)').length > 0
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
    entity.find(".product-variants.optional").each ->
      sum = sum + Number $(this).data('adjustment')
    sum

#######################################################################################################################

# Friendly flash message in case user tries to checkout without the add-to-cart button
  # being enabled
  entity.find(".add-to-cart-button").on('update',( ->
    if entity.find('.variant-options.required:not(.selected)').length > 0
      $(this).attr("style", "opacity: 0.5").addClass('disabled').tooltipster('enable');
    else
      $(this).removeAttr("style").removeClass("disabled").tooltipster('disable');
  ))

  entity.find('.add-to-cart-button').click (event) -> 
    if $(this).hasClass('disabled')
      false
