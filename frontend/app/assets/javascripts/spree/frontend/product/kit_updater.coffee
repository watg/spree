class @KitUpdater
  constructor: (@entity, @option_value) ->
    @option_values = @option_value.closest('.variant-option-values')
    @product_variants = @option_values.closest('.product-variants')
    @thumbs = @entity.find('ul.thumbnails li.tmb-product-parts')

  showThumbs: ->
    @thumbs.show()

  changeMainImage: ->
    thumb_url = @thumbs.first().find('a').attr('href')
    main_image = @entity.find('.main-image')
    main_image.find('img').attr('src', thumb_url)
    main_image.find('a').attr('href', thumb_url)

  validSelection: ->
    return this.getSelectedVariantId() of this.getTree()

  selectOption: ->
    variant_id = this.getSelectedVariantId()
    variant = this.getTree()[variant_id]

    part_id = @product_variants.data('adp-id')
    # Set the variant_id
    @product_variants.find('.selected-parts').val(variant_id)
    # Set the adjustments on the parts
    @product_variants.data('adjustment', variant['part_price'])
    if variant['image_url']
      $('.part-image-' + part_id).css('background-image', 'url(' + variant['image_url'] + ')')

  resetOption: ->
    part_id = @product_variants.data('adp-id')
    $('.part-image-' + part_id).css('background-image', 'none')
    selected_parts = @product_variants.find('.selected-parts')
    selected_parts.val(selected_parts.data('original-value'))
    @product_variants.data('adjustment', 0)

  getTree: ->
    return @product_variants.data('tree')

  getSelectedVariantId: ->
    selected_option_value = @product_variants.find('.option-value.selected')
    variant_id = selected_option_value.data('variant-id')
    return variant_id

  setOptionText: ->
    selected_presentation = @option_value.data('presentation')
    presentation_spans = @product_variants.find('span:not(.optional)')
    if core.isMobileWidthOrLess()
      presentation_spans.not(".mobile-product-presentation")
      .eq(0).text(selected_presentation)
    else
      presentation_spans.eq(0).text(selected_presentation)

  toogleSelect: ->
    @option_values.find('.option-value').removeClass('selected')
    @option_value.closest('.variant-options').addClass('selected')
    @option_value.addClass('selected')
