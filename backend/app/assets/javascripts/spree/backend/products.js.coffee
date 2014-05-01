jQuery ->
  $('form.edit_product').on 'click', '.remove_description', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('.product_description').hide()
    event.preventDefault()

  $('form.edit_product').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $('#product_targets').append($(this).data('fields').replace(regexp, time))
    event.preventDefault()