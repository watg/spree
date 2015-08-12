class @YarnAndWoolUpdater extends @ReadyMadeUpdater
  constructor: (@entity, @master_tree, @variants_total_on_hand) ->
    @cart_button = @entity.find('.add-to-cart-button')
    @stock_level = @entity.find('.stock-level')
    if core.isMobileWidthOrLess() == true
      @carousel = $('#carousel').data('owlCarousel')
      this.changeCarouselOptions()
      @carousel_thumbs = this.AddAllImagesToCarousel()
      this.addCarouselListners()
      this.addSelectorImages() # this is done by javascript due to a performance hack

  AddAllImagesToCarousel: ->
    variant_thumbs = []
    for key, option of @master_tree.colour
      clone = @entity
              .find('li.tmb-' +  option.variant.id + ' img').first()
              .clone().data("optionColour", key)
      variant_thumbs.push clone
    owl = $('#carousel')
    textholder = undefined
    booleanValue = false
    # remove all of the old images - if any present
    num_images = $('#carousel').data('owlCarousel').itemsAmount
    i = 0
    while i < num_images
      owl.data('owlCarousel').removeItem 0
      i++
    # Add relevant images
    variant_thumbs.forEach (image) ->
      image = $(image)
      owl.data('owlCarousel').addItem image
    return variant_thumbs
    
  changeCarouselOptions: ->
    @carousel.reinit({
      pagination: false,
      navigation: true,
      navigationText: [
        "<img src='https://s3-eu-west-1.amazonaws.com/assetswoolandthegangcom/static/yarn/arrow_left_black.png'>",
        "<img src='https://s3-eu-west-1.amazonaws.com/assetswoolandthegangcom/static/yarn/arrow_right_black.png'>"
      ]
    })

  addSelectorImages: ->
    master_tree = @master_tree
    $('.option-value').each ->
      $(this)
      .find('img').attr 'src', master_tree.colour[$(this).data().value].variant.part_image_url

  addCarouselListners: ->
    carousel_thumbs = @carousel_thumbs
    option_type_order = @entity.data('option-type-order')
    page_updater = this

    @carousel.options.afterMove = ->
      colour = carousel_thumbs[this.currentItem].data('optionColour')
      option_value = $("."+colour)
      selected_type = option_value.data('type')
      selected_value = option_value.data('value')
      selected_presentation = option_value.data('presentation')
      page_updater
      .toggleOptionValues(selected_type, selected_value, selected_presentation, option_type_order)
      page_updater.updateProductPage()

  toggleSelectionThumb: (colour) ->
    variant = @master_tree.colour[colour].variant
    $('.part-image').css('background-image', 'url(' + variant['image_url'] + ')')

  moveCarouselTo: (colour) ->
    element_number = 0
    @carousel_thumbs.forEach((elem, index) ->
      if elem.data("optionColour") == colour
        element_number = index
    )
    @carousel.goTo(element_number)

  updateProductPage: ->
    if this.getVariantDetails()
      this.updateUrl()
      this.updateSupplierDetails()
      this.setStockLevel(@variants_total_on_hand)
      this.setIsDigital()
      this.setPrices()
      if core.isMobileWidthOrLess() == true
        this.moveCarouselTo(@entity.find(".option-value.selected").data("value"))
        this.toggleSelectionThumb(@entity.find(".option-value.selected").data("value"))
      else
        this.toggleImages()
    else
      this.toggleOnColorSelector()
