core.suite.readyYarnAndWoolOptions = function(entity) {
  var option_type_order, option_value, option_values, page_updater, variants_total_on_hand;
  variants_total_on_hand = entity.parents(".wrapper-product-group").data('variants-total-on-hand');
  option_type_order = entity.data('option-type-order');
  option_values = entity.data('option-values') || [];
  page_updater = new YarnAndWoolUpdater(entity, entity.data('tree'), variants_total_on_hand);

  for (var i = 0, len = option_values.length; i < len; i++) {
    option_value = option_values[i];
    page_updater
    .toggleOptionValues(option_value[0], option_value[1], option_value[2], option_type_order);
  }

  page_updater.updateProductPage();

  entity.find('.option-value').click(function(event) {
    var selected_presentation, selected_type, selected_value;
    event.preventDefault();
    selected_type = $(this).data('type');
    selected_value = $(this).data('value');
    selected_presentation = $(this).data('presentation');
    page_updater
    .toggleOptionValues(selected_type, selected_value, selected_presentation, option_type_order);
    page_updater.updateProductPage();
  });

  entity.find(".optional-parts ul input").click(function(event) {
    page_updater.adjustPrices();
  });

  entity.find('.personalisations :checkbox').click(function(event) {
    page_updater.togglePersonalisations($(this), event);
    page_updater.adjustPrices();
  });

  entity.find('.personalisation-option-value').click(function(event) {
    page_updater.togglePersonalisationOptionValue($(this), event);
  });


  entity.find('.add-to-cart-button').click(function(event) {
    var key, last, message, missing_types;
    if ($(this).hasClass('disabled')) {
      missing_types = [];
      for (key in option_type_order) {
        if (!entity.find(".variant-option-values." + key).hasClass('selected')) {
          missing_types.push(key);
        }
      }
      last = missing_types.splice(-1, 1);
      message = "Please choose your " + missing_types.join(', ');
      if (missing_types.length > 0) {
        message = message + " and ";
      }
      message = message + last;
      entity.find('p.error').remove();
      entity.find('.add-to-cart')
      .prepend($("<p class='error'>" + message + "</p>")
      .hide()
      .fadeIn('slow').focus());
    }
  });

};
