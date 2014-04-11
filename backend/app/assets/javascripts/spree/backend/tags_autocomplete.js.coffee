$ = jQuery

$.fn.tagsAutocomplete = ->
  this.select2({
    placeholder: "Choose your tags"
    multiple: true
    minimumInputLength: 2
 
    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.tags_search, {
        ids: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data)
      )

    ajax: 
      url: Spree.routes.tags_search
      datatype: 'json'
      data: (term, page) ->
        {
          per_page: 10,
          page: page,
          q: {
            value_cont: term
          }
        }

      results: (data, page) ->
        {results: data}

    formatResult: (tag) ->
      return tag.value

    formatSelection: (tag) ->
      return tag.value
  }) 

