$ = jQuery

$.fn.indexPageAutocomplete = ->
  this.select2({
    placeholder: "Choose index page to assign"
    multiple: false
    minimumInputLength: 2
    
    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.index_pages_search, {
        id: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data[0])
      )

    ajax: 
      url: Spree.routes.index_pages_search
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

    formatResult: (index_page) ->
      return index_page.name

    formatSelection: (index_page) ->
      return index_page.name
  }) 
  