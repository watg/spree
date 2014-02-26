$ ->
  window.selected_currency = $('#currency-select select').val()
  $('#currency-select select').change ->
    # console.log "selected country"
    # console.log window.selected_currency
    $.ajax
      type: 'POST'
      url: $(this).data('href')
      data:
        currency: $(this).val()
      beforeSend: ->
        confirm = window.confirm('Note: If you change the currency, your items will no longer be available in your cart. Continue?')
        if confirm == false
          # console.log "Setting back the following:"
          # console.log window.selected_currency
          $('#currency-select select').val(window.selected_currency)
        return confirm
    .done ->
      window.location.reload()
