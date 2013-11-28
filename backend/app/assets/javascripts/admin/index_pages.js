$(document).ready(function () {
  'use strict';

  $.fn.itemAutocomplete = function() {
    // this.parent().children(".options_placeholder").attr('id', this.parent().data('index'))
    this.select2({
      placeholder: "Search item",
      minimumInputLength: 3,
      ajax: {
        url: Spree.url(Spree.routes.product_pages_search),
        datatype: 'json',
        data: function(term, page) {
          return {
            q: {
              "name_cont": term
            }
          }
        },
        results: function (data, page) {
          return { results: data }
        }
      },
      formatResult: function (item) {
        console.log("formatting");
        var itemTemplate = Handlebars.compile($('#item_autocomplete_template').text());
        return itemTemplate({ item: item });
      },
      formatSelection: function (item) {
        return item.name;
      }
    })

  }

  $('#item_autocomplete').itemAutocomplete();

});