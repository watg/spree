$ = jQuery

$.fn.productPageAutocomplete = ->
  this.select2({
    placeholder: "Select product page"
    multiple: false
    minimumInputLength: 2
    
    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.product_pages_search, {
        id: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data[0])
      )

    ajax: 
      url: Spree.routes.product_pages_search
      datatype: 'json'
      data: (term, page) ->
        {
          per_page: 10,
          page: page,
          q: {
            name_cont: term
          }
        }
      
      results: (data, page) ->
        {results: data}

    formatResult: (product_page) ->
      return product_page.name

    formatSelection: (product_page) ->
      return product_page.name
  }) 
  