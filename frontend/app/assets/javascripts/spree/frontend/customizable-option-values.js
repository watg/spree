core.suite.readyCustomizableVariantOptions = function(entity) {
// READY MADE
  var option_type_order,
      option_value,
      option_values,
      ready_made_updater,
      variants_total_on_hand;

  variants_total_on_hand = entity.parents(".wrapper-product-group").data('variants-total-on-hand');
  option_type_order = entity.data('option-type-order');
  option_values = entity.data('option-values') || [];
  ready_made_updater = new ReadyMadeUpdater(entity, entity.data('tree'), variants_total_on_hand);

  for (var i = 0, len = option_values.length; i < len; i++) {
    option_value = option_values[i];
    ready_made_updater.toggleOptionValues(option_value[0], option_value[1], option_value[2], option_type_order);
  }

  ready_made_updater.updateProductPage();

  entity.find('.assembled-options .option-value').click(function(event) {
    var selected_presentation, selected_type, selected_value;
    event.preventDefault();
    selected_type = $(this).data('type');
    selected_value = $(this).data('value');
    selected_presentation = $(this).data('presentation');
    ready_made_updater.toggleOptionValues(selected_type, selected_value, selected_presentation, option_type_order);
    return ready_made_updater.updateProductPage();
  });

  entity.find(".assembled-options .optional-parts ul input").click(function() {
    return ready_made_updater.adjustPrices();
  });

  entity.find('.assembled-options .personalisations :checkbox').click(function(event) {
    ready_made_updater.togglePersonalisations($(this), event);
    return ready_made_updater.adjustPrices();
  });

  entity.find('.assembled-options .personalisation-option-value').click(function(event) {
    return ready_made_updater.togglePersonalisationOptionValue($(this), event);
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
      entity.find('.add-to-cart').prepend($("<p class='error'>" + message + "</p>").hide().fadeIn('slow').focus());
      return false;
    }
  });

  entity.find('.assembly-menus .option-value').click(function(event) {
    var kit_updater;
    event.preventDefault();
    kit_updater = new KitUpdater(entity, $(this));
    if (kit_updater.option_value.hasClass('unavailable')) {
      return false;
    }
    kit_updater.showThumbs();
    kit_updater.changeMainImage();
    kit_updater.toogleSelect();
    kit_updater.setOptionText();
    if (kit_updater.validSelection()) {
      kit_updater.selectOption();
    } else {
      kit_updater.resetOption();
    }
    entity.find(".price").trigger('recalculate');
    entity.find(".add-to-cart-button").trigger('update');
    return core.suite.setAssemblyListHeights();
  });

  entity.find(".price").on("recalculate", function() {
    var adjustment;
    adjustment = KitUpdater.sumOfOptionalPartPrices(entity);
    return $(this).html(KitUpdater.formatPrice($(this).data("currency"), $(this).data("price") + adjustment));
  });

};
