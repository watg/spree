core.suite.readyVariantOptions = (entity) ->
# ANOTHER ONE HERE
  variants_total_on_hand = entity.parents(".wrapper-product-group").data('variants-total-on-hand')
  option_type_order = entity.data('option-type-order')
  option_values = entity.data('option-values') || []
  page_updater = new ReadyMadeUpdater(entity, entity.data('tree'), variants_total_on_hand)
  for option_value in option_values
    page_updater.toggleOptionValues(option_value[0], option_value[1], option_value[2], option_type_order)
  page_updater.updateProductPage()

  entity.find('.option-value').click (event)->
    event.preventDefault()
    selected_type = $(this).data('type')
    selected_value = $(this).data('value')
    selected_presentation = $(this).data('presentation')
    page_updater.toggleOptionValues(selected_type, selected_value, selected_presentation, option_type_order)
    page_updater.updateProductPage()
#  THIS BIT SHOULD BE REVIEWED

  # Then get it working with option_value changes
  entity.find(".optional-parts ul input").click (event) ->
    page_updater.adjustPrices()

  entity.find('.personalisations :checkbox').click (event) ->
    page_updater.togglePersonalisations($(this), event)
    page_updater.adjustPrices()

  # Toggle the personalisation option values
  entity.find('.personalisation-option-value').click (event) ->
    page_updater.togglePersonalisationOptionValue($(this), event)

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
