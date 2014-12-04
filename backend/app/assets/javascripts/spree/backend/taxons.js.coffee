$(document).ready ->
  window.suiteTemplate = Handlebars.compile($('#suite_template').text());
  $('#taxon_suites').sortable();
  $('#taxon_suites').on "sortstop", (event, ui) ->
    $.ajax
      url: Spree.routes.classifications_api,
      method: 'PUT',
      data:
        suite_id: ui.item.data('suite-id'),
        taxon_id: $('#taxon_id').val(),
        position: ui.item.index()

  if $('#taxon_id').length > 0
    $('#taxon_id').select2
      dropdownCssClass: "taxon_select_box",
      placeholder: Spree.translations.find_a_taxon,
      ajax:
        url: Spree.routes.taxons_search,
        datatype: 'json',
        data: (term, page) ->
          per_page: 50,
          page: page,
          # We don't want the overhead of selecting all the children
          without_children: true
          q:
            name_cont: term
        results: (data, page) ->
          more = page < data.pages;
          results: data['taxons'],
          more: more
      formatResult: (taxon) ->
        taxon.pretty_name;
      formatSelection: (taxon) ->
        taxon.pretty_name;

  $('#taxon_id').on "change", (e) ->
    el = $('#taxon_suites')
    $.ajax
      url: Spree.routes.taxon_suites_api,
      data:
        id: e.val
      success: (data) ->
        el.empty();
        if data.suites.length == 0
          $('#sorting_explanation').hide()
          $('#taxon_suites').html("<h4>" + Spree.translations.no_results + "</h4>")
        else
          for suite in data.suites
            # console.log suite.image === 'null'
            if suite.image != null && suite.image.mobile_url != undefined
              suite.image = suite.image.mobile_url
            el.append(suiteTemplate({ suite: suite }))
          $('#sorting_explanation').show()

