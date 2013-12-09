$ = jQuery

$.fn.indexPageAutocomplete = ->
  this.select2({
    placeholder: "Choose index pages to assign"
    multiple: true
    minimumInputLength: 2
    
    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.index_pages_search, {
        ids: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data)
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
        {
          results: data
        }

    formatResult: (index_page) ->
      return index_page.name

    formatSelection: (index_page) ->
      return index_page.name
  }) 
  