$ = jQuery

$.fn.productGroupAutocomplete = ->
  this.select2({
    placeholder: ""
    multiple: true
    minimumInputLength: 2
 
    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.product_groups_search, {
        ids: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data)
      )

    ajax: 
      url: Spree.routes.product_groups_search
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

    formatResult: (product_group) ->
      return product_group.name

    formatSelection: (product_group) ->
      return product_group.name
  }) 

