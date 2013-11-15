$(document).ready(function () {
  'use strict';

  if ($('#product_page_product_group_ids').length > 0) {
    $('#product_page_product_group_ids').select2({
      placeholder: "Choose product groups",
      multiple: true,
      minimumInputLength: 2,
      initSelection: function (element, callback) {
        var url = Spree.url(Spree.routes.product_groups_search, {
          ids: element.val()
        });
        return $.getJSON(url, null, function (data) {
          return callback(data);
        });
      },
      ajax: {
        url: Spree.routes.product_groups_search,
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
          return {
            results: data
          };
        }
      },
      formatResult: function (product_group) {
        return product_group.name;
      },
      formatSelection: function (product_group) {
        return product_group.name;
      }
    });
  }
});