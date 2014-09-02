jQuery.fn.productAutocompleteSingle = ->
  this.select2({
    placeholder: "Choose a product"
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
        per_page: 10
        page: page
        q:
          name_cont: term
          sku_cont: term
        m: 'OR'
        # token: Spree.api_key


      results: (data, page) ->
        {results: data.products || []}

    formatResult: (product) ->
      if product.variant?.images[0]?.mini_url != undefined
        product.image = product.variant.images[0].mini_url
      productAutocompleteTemplate({ product: product })

    formatSelection: (product) ->
      product.name
  })


$ ->
  $('.product_autocomplete').productAutocompleteSingle()
  window.productAutocompleteTemplate = Handlebars.compile($('#product_autocomplete_template').text())