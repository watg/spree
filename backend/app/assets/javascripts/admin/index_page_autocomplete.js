$(document).ready(function () {
  'use strict';

  var index_page_dropdown = $('.index-page-dropdown').first();

  if (index_page_dropdown.length > 0) {
    index_page_dropdown.select2({
      placeholder: "Choose index pages to assign",
      multiple: true,
      minimumInputLength: 2,
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
            per_page: 10,
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