jQuery ->
  if $('#taxon_page_type').val() == 'Spree::ProductPage'
    $('#taxon_page_id').productPageAutocomplete()
  else
    $('#taxon_page_id').indexPageAutocomplete()
  
  