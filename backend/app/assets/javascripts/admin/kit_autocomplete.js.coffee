$ = jQuery

$.fn.kitAutocomplete = (product_group_ids) ->
  this.select2({
    placeholder: "Choose kit"
    multiple: false
    minimumInputLength: 2

    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.product_search, {
        id: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data[0])
      )

    ajax: 
      url: Spree.routes.product_search
      datatype: 'json'
      data: (term, page) ->
        {
          per_page: 10,
          page: page,
          q: {
            name_cont: 'moby' 
          }
        }

      results: (data, page) ->
        {results: data}

    formatResult: (product) ->
      return product.name

    formatSelection: (product) ->
      return product.name
  }) 

