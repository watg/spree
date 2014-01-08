jQuery.fn.kitAutocomplete =(product_group_ids) ->
  this.select2({
    placeholder: "Choose a kit"
    minimumInputLength: 2

    initSelection: (element, callback) ->
      url = Spree.url(Spree.routes.product_search, {
        ids: element.val()
      })
      $.getJSON(url, null, (data) ->
        callback(data.products[0])
      )

    ajax: 
      url: Spree.routes.product_search
      datatype: 'json'
      data: (term, page) ->
        {
          per_page: 10,
          page: page,
          q: {
            name_cont: term, 
            product_type_eq: 'kit', 
            product_group_in: product_group_ids 
          }
        }

      results: (data, page) ->
        {results: data.products}

    formatResult: (product) ->
      variant = product["variant"]
      variant.name = product.name
      if variant["images"][0] and variant["images"][0].mini_url
        variant.image = variant.images[0].mini_url

      variantTemplate = Handlebars.compile($('#variant_autocomplete_template').text());
      variantTemplate({ variant: variant })

    formatSelection: (product) ->
      console.log "tra la " + product.name
      product.name
  }) 

