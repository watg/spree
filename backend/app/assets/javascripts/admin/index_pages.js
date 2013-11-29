$(document).ready(function () {
  'use strict';

  function selectContext(){
    var options = {};
    if ($('#item_type').val() == 'Spree::ProductPage'){
      options = {
        url: Spree.routes.product_pages_search,
        param_name: "name_cont",
        template: '#item_autocomplete_template',
        d: null
      }
    }else{
      options = {
        url:  Spree.routes.variants_search,
        param_name: "product_name_or_sku_cont",
        template: '#variant_autocomplete_template',
        d: 'variants'
      }
    }
    return options;
  }
  

  $.fn.itemAutocomplete = function() {
    var context = selectContext();
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
          return params;
        },
        results: function (data, page) {
          return { results: (context.d ? data.variants : data) }}
      },
      formatResult: function (item) {
        var itemTemplate = Handlebars.compile($(context.template).text());

        if (item["images"][0] != undefined && item["images"][0].urls != undefined) {
          item.image = item.images[0].urls.mini
        }
        
        return itemTemplate({ item: item , variant: item});
      },
      formatSelection: function (item) {
        return item.name;
      }
    })

  }

  
  $('#item_type').on('change', function(){
    $('#item_autocomplete').itemAutocomplete();  
  });
  
  $('#item_autocomplete').itemAutocomplete();
});
