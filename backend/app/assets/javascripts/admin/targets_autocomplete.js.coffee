$ = jQuery

$.fn.targetsAutocomplete = ->
  this.select2({
    placeholder: "Choose your targets"
    multiple: true
    minimumInputLength: 2
 
    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.targets_search, {
        ids: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data)
      )

    ajax: 
      url: Spree.routes.targets_search
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

    formatResult: (target) ->
      return target.name

    formatSelection: (target) ->
      return target.name
  }) 

