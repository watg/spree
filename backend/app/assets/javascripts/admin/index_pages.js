$(document).ready(function () {
  'use strict';

  $.fn.itemAutocomplete = function(context) {
    this.select2({
      placeholder: "Search item",
      minimumInputLength: 3,
      ajax: {
        url: context.url,
        datatype: 'json',
        data: function(term, page) {
          var params = {
            q: {
            }
          };
          params['q'][context.param_name] = term;
          if (context.include_product_page) {
            params['product_page_id'] = $("#product_page_autocomplete").val();
          }

          return params;
        },
        results: function (data, page) {
          return { results: (context.d ? data.variants : data) };
        }
      },
      formatResult: function (item) {
        var itemTemplate = Handlebars.compile($(context.template).text());

        if (item["images"] != undefined && item["images"][0] != undefined && item["images"][0].urls != undefined) {
          item.image = item.images[0].urls.mini;
        }

        return itemTemplate({ item: item , variant: item});
      },
      formatSelection: function (item) {
        return item.name;
      }
    });
  };
  
});
