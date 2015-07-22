core.suite.readyKitVariantOptions = (entity) ->
  entity.find('.option-value').click (event)->
    event.preventDefault()
    kit_updater = new KitUpdater(entity, $(this))

    if kit_updater.option_value.hasClass('unavailable')
      return false

    kit_updater.showThumbs()
    kit_updater.changeMainImage()
    kit_updater.toogleSelect()
    kit_updater.setOptionText()

    if kit_updater.validSelection()
      kit_updater.selectOption()
    else
      kit_updater.resetOption()

    entity.find(".price").trigger('recalculate')
    entity.find(".prices").trigger('update')
    entity.find(".add-to-cart-button").trigger('update')

    # Adjust list heights
    core.suite.setAssemblyListHeights()

###### Prices #########################################################################################################

  entity.find(".prices").on('update',( ->
    if entity.find('.variant-options.required:not(.selected)').length > 0
      $(this).find('.price').addClass('unselected')
    else
      $(this).find('.price').removeClass('unselected')
  ))

  entity.find(".price").on('recalculate',( ->
    adjustment = KitUpdater.sumOfOptionalPartPrices(entity)
    $(this).html( KitUpdater.formatPrice($(this).data('currency'), $(this).data('price') + adjustment ) )
  ))

#######################################################################################################################

# Friendly flash message in case user tries to checkout without the add-to-cart button
  # being enabled
  entity.find(".add-to-cart-button").on('update',( ->
    if entity.find('.variant-options.required:not(.selected)').length > 0
      $(this).attr("style", "opacity: 0.5").addClass('disabled tooltip');
    else
      $(this).removeAttr("style").removeClass("disabled tooltip");
  ))

  entity.find('.add-to-cart-button').click (event) ->
    if $(this).hasClass('disabled')
      false
