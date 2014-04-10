formatProductResult = function(product) {
  var variant = product["variant"];
  variant.name = product.name;
  if (variant["images"][0] != undefined && variant["images"][0].mini_url != undefined) {
    variant.image = variant.images[0].mini_url;
  }

  variantTemplate = Handlebars.compile($('#variant_autocomplete_template').text());
  return variantTemplate({ variant: variant });
}

$.fn.productAutocomplete = function () {
  'use strict';

  this.select2({
    minimumInputLength: 2,
    multiple: true,
    initSelection: function (element, callback) {
      $.get(Spree.routes.product_search, {
        ids: element.val().split(',')
      }, function (data) {
        callback(data.products);
      });
    },
    ajax: {
      url: Spree.routes.product_search,
      datatype: 'json',
      data: function (term, page) {
        return {
          q: {
            name_cont: term,
            sku_cont: term
          },
          m: 'OR',
          token: Spree.api_key
        };
      },
      results: function (data, page) {
        var products = data.products ? data.products : [];
        return {
          results: products
        };
      }
    },
    formatResult: formatProductResult,
    formatSelection: function (product) {
      return product.name;
    }
  });
};

$(document).ready(function () {
  $('.product_picker').productAutocomplete();
});