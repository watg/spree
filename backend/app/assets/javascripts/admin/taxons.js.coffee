jQuery ->
  determineTaxonPageSelect2 = ->
    if $('#taxon_page_type').val() == 'Spree::ProductPage'
      $('#taxon_page_id').productPageAutocomplete()
    else
      $('#taxon_page_id').indexPageAutocomplete()
  
  $('#taxon_page_type').on 'change', ->
    $('#taxon_page_id').val("")
    determineTaxonPageSelect2()

  determineTaxonPageSelect2()