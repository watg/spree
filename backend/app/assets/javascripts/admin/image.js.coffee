Spree.ready ($) ->
  $('.activate_personalisation:checkbox').click (event) ->
    image_id = $(this).val()
    if $(this).is(':checked')
      $('.image-variant-' + image_id).hide()
      $('.image-personalisation-' + image_id).show()
    else
      $('.image-variant-' + image_id).show()
      $('.image-personalisation-' + image_id).hide()
