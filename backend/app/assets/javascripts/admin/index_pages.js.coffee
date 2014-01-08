jQuery ->
  setVariantAutocomplete = (product_page) ->
    product_page_id = product_page.val()
    variant_select2 = product_page.parent().find('input[type=hidden]')[1]
    $(variant_select2).variantAutocomplete(product_page_id)

  $('.index-page-product-page-ids').each ->
    $(this).productPageAutocomplete()
    setVariantAutocomplete($(this))
    
    $(this).on 'change', ->
      setVariantAutocomplete($(this))

  window.bindIndexPageItemNewActions = ->
    $('#index_page_item_product_page_id').productPageAutocomplete();
    $('#index_page_item_variant_id').variantAutocomplete()

    $('#index_page_item_product_page_id').change ->
      product_page_id = $(this).val()
      $('#index_page_item_variant_id').variantAutocomplete(product_page_id)


  bindIndexPageItemNewActions()