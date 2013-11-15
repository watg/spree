$(document).ready(function () {
  'use strict';

  var index_page_dropdown = null;

  if ($('#product_index_page_ids').length > 0)
    index_page_dropdown = $('#product_index_page_ids');
  else if ($('#variant_index_page_ids').length > 0)
    index_page_dropdown = $('#variant_index_page_ids');
  else if ($('#product_page_index_page_ids').length > 0)
    index_page_dropdown = $('#product_page_index_page_ids');

  if (index_page_dropdown) {
    index_page_dropdown.select2({
      placeholder: "Choose index pages to assign",
      multiple: true,
      initSelection: function (element, callback) {
        var url = Spree.url(Spree.routes.index_pages_search, {
          ids: element.val()
        });
        return $.getJSON(url, null, function (data) {
          return callback(data);
        });
      },
      ajax: {
        url: Spree.routes.index_pages_search,
        datatype: 'json',
        data: function (term, page) {
          return {
            per_page: 50,
            page: page,
            q: {
              name_cont: term
            }
          };
        },
        results: function (data, page) {
          console.log(data)
          return {
            results: data
          };
        }
      },
      formatResult: function (index_page) {
        return index_page.name;
      },
      formatSelection: function (index_page) {
        return index_page.name;
      }
    });
  }
});