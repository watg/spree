class @ReadyMadeUpdater
  constructor: (@entity, @master_tree, @variants_total_on_hand) ->


  updateProductPage: ->
    if this.getVariantDetails()
      this.updateUrl()
      this.updateSupplierDetails()
      this.setStockLevel(@variants_total_on_hand)
      this.setIsDigital()
      this.setPrices()
      if core.isMobileWidthOrLess() == true
        # if option values had the class langauge when is was clicked - dont toggle
        if @entity.find('.assembled-options .option-value.language').length <= 0
          this.toggleCarouselImages()
      else
        this.toggleImages()
    else
      this.toogleOnColorSelector()


  updateSupplierDetails: ->
    suppliers = this.getVariantDetails().suppliers
    names = []
    profiles = []

    # Loop through suppliers
    for index, supplier of suppliers
      for index, items of supplier
        names.push(items.nickname)
        if items.nickname != null
          profiles.push('<h6>' + items.nickname.toUpperCase() +
                        '</h6> ' + '<p>' + items.profile + '</p>')

    # Prep names for output...
    if core.isMobileWidthOrLess() == true
      names = ' #madeunique'
    else if names.length > 1
      mNames = names.slice(0, names.length - 1)
      .join(', ') + " and " + names.slice(-1)

      names = ' #madeunique <span>by ' + mNames + '</span>'
    else
      names = ' #madeunique <span>by WATG</span>'

    # Prep profiles for output...
    if profiles.length > 1
      profiles = profiles.join('<br/><br/>')

    # Update heading and reveal panel
    heading = @entity.find('.suppliers')
    img = heading.find('img')
    heading.empty().append(img).append(names)
    @entity.find('.profiles').html(profiles)


  toogleSelect: (selected_type, selected_value) ->
    @entity.find(".assembled-options .option-value.#{selected_type}").removeClass('selected')
    @entity.find(".assembled-options .option-value.#{selected_type}.#{selected_value}").addClass('selected')
    @entity.find(".assembled-options .variant-option-values.#{selected_type}").addClass('selected')


  getVariantDetails: ->
    selection_details = this.getSelectionDetails()
    # If the node is 'variant' then we have no more options to select
    # so get the pricing info and update the prices
    if 'variant' of selection_details.tree
      return selection_details.tree['variant']
    else
      return null

  toggleOptionValues: (selected_type, selected_value, selected_presentation, option_type_order) ->
    # If selected type value is unavailable, then return false
    if @entity.find(".assembled-options .option-value.#{selected_type}.#{selected_value}").hasClass('unavailable')
      return false

    # Update the color-text value if type is selected_type is colour
    if (selected_type == 'colour' || selected_type == 'icon-colour')
      selector = "span.color-value.#{selected_type}"
      $(selector).text(selected_presentation)

    this.toogleSelect(selected_type, selected_value)
    next_type = option_type_order[selected_type]

    while (next_type)
      option = @entity.find(".assembled-options .option-value.#{next_type}")
      @entity.find(".assembled-options .option-value.#{next_type}").removeClass('selected')
      .addClass('unavailable').addClass('locked')
      @entity.find(".assembled-options .variant-option-values.#{next_type}").removeClass('selected')
      next_type = option_type_order[next_type]

    selection_details = this.getSelectionDetails()
    this.showOptionsAvaliability(selection_details.type, selection_details.tree)

  getSelectionDetails: ->
    type = ""
    value = ""
    tree = @master_tree
    @entity.find('.assembled-options .option-value.selected').each ->
      option_value = $(this)
      type =  option_value.data('type')
      value = option_value.data('value')
      tree = tree[type][value]
    return { type: type, value: value, tree: tree }

  showOptionsAvaliability: (type, tree) ->
    # get the current node of the tree, which will be the type of option
    # value we have to choose a value for, and make only those that
    # should be available, available
    for type, sub_tree of tree
      @entity.find(".assembled-options .option-value.#{type}").each ->
        option_value = $(this)
        if option_value.data('value') of sub_tree
          option_value.removeClass('unavailable')
          option_value.removeClass('locked')


  adjustPrices: ->
    normal_price = @entity.find("span.normal-price").data('price')
    sale_price = @entity.find("span.sale-price").data('price')
    adjustment = this.getAdjustmentPrice()
    @entity.find('.normal-price').html( this.formatPrice(normal_price + adjustment ) )
    @entity.find('.sale-price').html( this.formatPrice(sale_price + adjustment ) )

  getAdjustmentPrice: ->
    optional_part_price = this.sumOfOptionalPartPrices()
    personalisation_price = this.sumOfPersonalisationPrices()
    optional_part_price + personalisation_price

  formatPrice: (pence) ->
    currencySymbol = @entity.find(".normal-price").data('currency')
    "#{currencySymbol}#{(pence / 100).toFixed(2)}"

  sumOfPersonalisationPrices: ->
    sum = 0
    @entity.find(".assembled-options .personalisations input:checked").each ->
      sum = sum + Number $(this).data('price')
    sum

  sumOfOptionalPartPrices: ->
    sum = 0
    @entity.find(".assembled-options .optional-parts ul input:checked").each ->
      sum = sum + ( Number $(this).data('price') * $(this).data('quantity') )
    sum

  setPrices: ->
    variant_details = this.getVariantDetails()
    variant_id      = variant_details.id
    normal_price    = variant_details.normal_price
    sale_price      = variant_details.sale_price
    in_sale         = variant_details.in_sale

    @entity.find('.assembled-options .variant_id, form[data-form-type="variant"] input[name$="[variant_id]"]')
            .val(variant_id)

    adjustment = this.getAdjustmentPrice()

    # Update the data attributes, incase variants have different prices to each other
    @entity.find("span.normal-price").data('price', normal_price)
    @entity.find("span.sale-price").data('price', sale_price)

    @entity.find('.normal-price').html( this.formatPrice(normal_price + adjustment ) )
    @entity.find('.sale-price').html( this.formatPrice(sale_price + adjustment ) )

    @entity.find('.normal-price').addClass('selling').removeClass('unselected')
    @entity.find('.add-to-cart-button').removeAttr("style").removeClass("disabled")

    if in_sale == true
      @entity.find('.normal-price').addClass('was')
      @entity.find('.sale-price').addClass('now selling').removeClass('hide')
    else
      @entity.find('.normal-price').removeClass('was')
      @entity.find('.sale-price').removeClass('now selling').addClass('hide')

  setStockLevel: (variants_total_on_hand) ->
    variant_number = this.getVariantDetails().number
    total_on_hand = variants_total_on_hand[variant_number]

    if total_on_hand
      if core.isMobileWidthOrLess() == false
        @entity.find('.stock-level').css('display', 'initial')
      else
        @entity.find('.stock-level').css('display', 'block')
      @entity.find('.stock-value').text(total_on_hand + ' left')
    else
      @entity.find('.stock-level').css('display', 'none')

  setIsDigital: ->
    if this.getVariantDetails().is_digital
      if core.isMobileWidthOrLess() == false
        @entity.find('.digital-available').css('display', 'initial')
      else
        @entity.find('.digital-available').css('display', 'block')
    else
      @entity.find('.digital-available').css('display', 'none')

  updateUrl: ->
    number = this.getVariantDetails().number
    if number.length > 1

      # Get paths
      path = core.getUrlPathAsArray()

      # If we have a query string, ensure we append it to the updated URL
      query = ''
      if window.location.search
        query = window.location.search

      # Update the URL
      new_url = '/' + path[1] + '/' + path[2] + '/' + path[3] + '/' + number + query
      History.replaceState(null, null, new_url)

  # Modify the images based on the selected variant
  toggleImages: (variant_id) ->
    variant_id = variant_id || this.getVariantDetails().id
    all_thumbs = @entity.find('li.vtmb')
    all_thumbs.hide()
    variant_thumbs = @entity.find('li.tmb-' + variant_id)
    variant_thumbs.show()

    thumb = @entity.find("ul.thumbnails li.tmb-" + variant_id + ":first").eq(0)
    if (thumb.length == 0)
      thumb = @entity.find('ul.thumbnails li').eq(0)
    this.changeMainImage(thumb)

  toggleCarouselImages: ->
    variant_id = this.getVariantDetails().id
    variant_thumbs = @entity.find('li.tmb-' + variant_id)
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
    variant_thumbs.toArray().forEach (image) ->
      image = $(image).find('img')
      owl.data('owlCarousel').addItem image.clone()

  changeMainImage: (thumb) ->
    newImg = thumb.find('a').attr('href')
    if newImg
      @entity.find('ul.thumbnails li').removeClass('selected')
      thumb.addClass('selected')
      @entity.find('.main-image img').attr('src', newImg)
      @entity.find('.main-image img')
      .attr('data-zoomable', newImg.replace('product', 'original'))
      @entity.find('.main-image a').attr('href', newImg)
      @entity.find(".main-image").data('selectedThumb', newImg)
      #$("#main-image").data('selectedThumbId', thumb.attr('id'))

  togglePersonalisationOptionValue: (element, event) ->
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
    selected_type_selector = ".personalisation-option-value.#{selected_type}.#{selected_value}"
    if personalisation.find(selected_type_selector).hasClass('unavailable')
      return false

    # Ensure the option you selected clicked is selected and
    # unselect all the other options at this level
    personalisation.find(".personalisation-option-value.#{selected_type}").removeClass('selected')
    personalisation.find(".personalisation-option-value.#{selected_type}.#{selected_value}")
    .addClass('selected')

  togglePersonalisations: (checkbox, event) ->
    personalisation = checkbox.parents('.personalisation')
    personalisation_id = checkbox.val()
    thumbs = @entity.find("ul.thumbnails li.tmb-personalisation-" + personalisation_id)

    if checkbox.is(':checked')
      if thumbs.length > 0
        thumbs.show()
        thumb = thumbs.first()
        changeMainImage(thumb)
      personalisation.find('.personalisation-options').show()
      personalisation.find('.personalisation-option-values').show()

    else
      if thumbs.length > 0
        thumbs.hide()
        # When you deselect the peronalisation options, select
        # the first visible image from the remaining thumbnails
        thumb = @entity.find("ul.thumbnails li.vtmb:visible").first()
        changeMainImage(thumb)
      personalisation.find('.personalisation-options').hide()
      personalisation.find('.personalisation-option-values').hide()

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
    # toggleImages.
    #
    # I copied/pasted some code from toggleOptionValues. You could refactor
    # this into a function but I decided it was less messy to keep all of this
    # horror in a self contained function of shit, rather than smearing it out
    # across other functions.
  toogleOnColorSelector: ->
    node = @master_tree
    @entity.find('.option-value.selected').each ->
      option_value = $(this)
      type =  option_value.data('type')
      value = option_value.data('value')
      node = node[type][value]
    find_first_variant = (tree) ->
      if(tree["variant"])
        tree["variant"] || find_first_variant(tree[Object.keys(tree)[0]])
    first_variant = find_first_variant(node)
    if first_variant
      this.toggleImages(first_variant['id'])
