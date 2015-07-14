var adjust_prices, change_main_image, format_price, get_adjustment_price, set_is_digital, set_prices, set_stock_level, sum_of_optional_part_prices, sum_of_personalisation_prices, toggle_carousel_images, toggle_images, toggle_option_values, toggle_personalisation_option_value, toggle_personalisations, update_supplier_details, update_url;

core.suite.readyCustomizableVariantOptions = function(entity) {
  function topPart(){
    var j, len, master_tree, option_type_order, option_value, option_values, variant_details, variants_total_on_hand;
    master_tree = entity.data('tree');
    option_type_order = entity.data('option-type-order');
    option_values = entity.data('option-values') || [];
    variants_total_on_hand = entity.parents(".wrapper-product-group").data('variants-total-on-hand');
    variant_details = null;

    for (j = 0, len = option_values.length; j < len; j++) {
      option_value = option_values[j];
      variant_details = toggle_option_values(entity, option_value[0], option_value[1], option_value[2], option_type_order, master_tree);
    }

    if (variant_details) {
      update_supplier_details(entity, variant_details['suppliers']);
      set_stock_level(entity, variants_total_on_hand, variant_details['number']);
      set_is_digital(entity, variant_details['is_digital']);
      set_prices(entity, variant_details['id'], variant_details['normal_price'], variant_details['sale_price'], variant_details['in_sale']);
      entity.find('li.tmb-' + variant_details['id']).show();
    }

    entity.find(".optional-parts ul input").click(function(event) {
      return adjust_prices(entity);
    });

    entity.find('.personalisations :checkbox').click(function(event) {
      toggle_personalisations(entity, $(this), event);
      return adjust_prices(entity);
    });

    entity.find('.personalisation-option-value').click(function(event) {
      return toggle_personalisation_option_value(entity, $(this), event);
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

    return entity.find('.assembled-options .option-value').click(function(event) {
      var find_first_variant, node, selected_presentation, selected_type, selected_value;
      event.preventDefault();
      selected_type = $(this).data('type');
      selected_value = $(this).data('value');
      selected_presentation = $(this).data('presentation');
      variant_details = toggle_option_values(entity, selected_type, selected_value, selected_presentation, option_type_order, master_tree);
      if (variant_details) {
        update_url(entity, variant_details['number']);
        update_supplier_details(entity, variant_details['suppliers']);
        set_stock_level(entity, variants_total_on_hand, variant_details['number']);
        set_is_digital(entity, variant_details['is_digital']);
        set_prices(entity, variant_details['id'], variant_details['normal_price'], variant_details['sale_price'], variant_details['in_sale']);
        if (core.isMobileWidthOrLess() === true) {
          if (entity.find('.assembled-options .option-value.language').length <= 0) {
            return toggle_carousel_images(entity, variant_details['id']);
          }
        } else {
          return toggle_images(entity, variant_details['id']);
        }
      } else {
        node = master_tree;
        entity.find('.assembled-options .option-value.selected').each(function() {
          var type, value;
          option_value = $(this);
          type = option_value.data('type');
          value = option_value.data('value');
          return node = node[type][value];
        });
        find_first_variant = function(tree) {
          return tree["variant"] || find_first_variant(tree[Object.keys(tree)[0]]);
        };
        return toggle_images(entity, find_first_variant(node)['id']);
      }
    });
  };

  toggle_option_values = function(entity, selected_type, selected_value, selected_presentation, option_type_order, master_tree) {
    var next_type, selector, sub_tree, tree, type;
    if (selected_type === 'colour' || selected_type === 'icon-colour') {
      selector = "span.color-value." + selected_type;
      $(selector).text(selected_presentation);
    }
    if (entity.find(".assembled-options .option-value." + selected_type + "." + selected_value).hasClass('unavailable')) {
      return false;
    }
    entity.find(".assembled-options .option-value." + selected_type).removeClass('selected');
    entity.find(".assembled-options .option-value." + selected_type + "." + selected_value).addClass('selected');
    entity.find(".variant-option-values." + selected_type).addClass('selected');
    entity.find('.normal-price').addClass('price now unselected').removeClass('was');
    entity.find('.sale-price').addClass('hide').removeClass('selling');
    entity.find('.add-to-cart-button').attr("style", "opacity: 0.5").addClass('disabled');
    next_type = option_type_order[selected_type];
    while (next_type) {
      entity.find(".assembled-options .option-value." + next_type).removeClass('selected').addClass('unavailable').addClass('locked');
      entity.find(".variant-option-values." + next_type).removeClass('selected');
      next_type = option_type_order[next_type];
    }
    tree = master_tree;
    entity.find('.assembled-options .option-value.selected').each(function() {
      var option_value, type, value;
      option_value = $(this);
      type = option_value.data('type');
      value = option_value.data('value');
      tree = tree[type][value];
      if ((selected_type === type) && (selected_value === value)) {
        return false;
      }
    });
    if ('variant' in tree) {
      return tree['variant'];
    } else {
      for (type in tree) {
        sub_tree = tree[type];
        entity.find(".assembled-options .option-value." + type).each(function() {
          var option_value;
          option_value = $(this);
          if (option_value.data('value') in sub_tree) {
            option_value.removeClass('unavailable');
            return option_value.removeClass('locked');
          }
        });
      }
    }
    return null;
  };

  adjust_prices = function(entity) {
    var adjustment, normal_price, sale_price;
    normal_price = entity.find("span.normal-price").data('price');
    sale_price = entity.find("span.sale-price").data('price');
    adjustment = get_adjustment_price(entity);
    entity.find('.normal-price').html(format_price(entity, normal_price + adjustment));
    return entity.find('.sale-price').html(format_price(entity, sale_price + adjustment));
  };

  get_adjustment_price = function(entity) {
    var optional_part_price, personalisation_price;
    optional_part_price = sum_of_optional_part_prices(entity);
    personalisation_price = sum_of_personalisation_prices(entity);
    return optional_part_price + personalisation_price;
  };

  format_price = function(entity, pence) {
    var currencySymbol;
    currencySymbol = entity.find(".normal-price").data('currency');
    return "" + currencySymbol + ((pence / 100).toFixed(2));
  };

  sum_of_personalisation_prices = function(entity) {
    var sum;
    sum = 0;
    entity.find(".personalisations input:checked").each(function() {
      return sum = sum + Number($(this).data('price'));
    });
    return sum;
  };

  sum_of_optional_part_prices = function(entity) {
    var sum;
    sum = 0;
    entity.find(".optional-parts ul input:checked").each(function() {
      return sum = sum + (Number($(this).data('price') * $(this).data('quantity')));
    });
    return sum;
  };

  set_prices = function(entity, variant_id, normal_price, sale_price, in_sale) {
    var adjustment;
    entity.find('.variant_id, form[data-form-type="variant"] input[name$="[variant_id]"]').val(variant_id);
    adjustment = get_adjustment_price(entity);
    entity.find("span.normal-price").data('price', normal_price);
    entity.find("span.sale-price").data('price', sale_price);
    entity.find('.normal-price').html(format_price(entity, normal_price + adjustment));
    entity.find('.sale-price').html(format_price(entity, sale_price + adjustment));
    entity.find('.normal-price').addClass('selling').removeClass('unselected');
    entity.find('.add-to-cart-button').removeAttr("style").removeClass("disabled");
    if (in_sale === true) {
      entity.find('.normal-price').addClass('was');
      return entity.find('.sale-price').addClass('now selling').removeClass('hide');
    } else {
      entity.find('.normal-price').removeClass('was');
      return entity.find('.sale-price').removeClass('now selling').addClass('hide');
    }
  };

  set_stock_level = function(entity, variants_total_on_hand, variant_number) {
    var total_on_hand;
    total_on_hand = variants_total_on_hand[variant_number];
    if (total_on_hand) {
      if (core.isMobileWidthOrLess() === false) {
        entity.find('.stock-level').css('display', 'initial');
      } else {
        entity.find('.stock-level').css('display', 'block');
      }
      return entity.find('.stock-value').text(total_on_hand + ' left');
    } else {
      return entity.find('.stock-level').css('display', 'none');
    }
  };

  set_is_digital = function(entity, is_digital) {
    if (is_digital) {
      if (core.isMobileWidthOrLess() === false) {
        return entity.find('.digital-available').css('display', 'initial');
      } else {
        return entity.find('.digital-available').css('display', 'block');
      }
    } else {
      return entity.find('.digital-available').css('display', 'none');
    }
  };

  update_url = function(entity, number) {
    var path, query;
    if (number.length > 1) {
      path = core.getUrlPathAsArray();
      query = '';
      if (window.location.search) {
        query = window.location.search;
      }
      return History.replaceState(null, null, '/' + path[1] + '/' + path[2] + '/' + path[3] + '/' + number + query);
    }
  };

  update_supplier_details = function(entity, suppliers) {
    var heading, img, index, items, mNames, names, profiles, supplier;
    names = [];
    profiles = [];
    for (index in suppliers) {
      supplier = suppliers[index];
      for (index in supplier) {
        items = supplier[index];
        names.push(items.nickname);
        if (items.nickname !== null) {
          profiles.push('<h6>' + items.nickname.toUpperCase() + '</h6> ' + '<p>' + items.profile + '</p>');
        }
      }
    }
    if (core.isMobileWidthOrLess() === true) {
      names = ' #madeunique';
    } else if (names.length > 1) {
      mNames = names.slice(0, names.length - 1).join(', ') + " and " + names.slice(-1);
      names = ' #madeunique <span>by ' + mNames + '</span>';
    } else {
      names = ' #madeunique <span>by WATG</span>';
    }
    if (profiles.length > 1) {
      profiles = profiles.join('<br/><br/>');
    }
    heading = entity.find('.suppliers');
    img = heading.find('img');
    heading.empty().append(img).append(names);
    return entity.find('.profiles').html(profiles);
  };

  toggle_images = function(entity, variant_id) {
    var all_thumbs, thumb, variant_thumbs;
    all_thumbs = entity.find('li.vtmb');
    all_thumbs.hide();
    variant_thumbs = entity.find('li.tmb-' + variant_id);
    variant_thumbs.show();
    thumb = entity.find("ul.thumbnails li.tmb-" + variant_id + ":first").eq(0);
    if (thumb.length === 0) {
      thumb = entity.find('ul.thumbnails li').eq(0);
    }
    return change_main_image(entity, thumb);
  };

  toggle_carousel_images = function(entity, variant_id) {
    var booleanValue, i, num_images, owl, textholder, variant_thumbs;
    variant_thumbs = entity.find('li.tmb-' + variant_id);
    owl = $('#carousel');
    textholder = void 0;
    booleanValue = false;
    num_images = $('#carousel').data('owlCarousel').itemsAmount;
    i = 0;
    while (i < num_images) {
      owl.data('owlCarousel').removeItem(0);
      i++;
    }
    return variant_thumbs.toArray().forEach(function(image) {
      image = $(image).find('img');
      return owl.data('owlCarousel').addItem(image.clone());
    });
  };

  change_main_image = function(entity, thumb) {
    var newImg;
    newImg = thumb.find('a').attr('href');
    if (newImg) {
      entity.find('ul.thumbnails li').removeClass('selected');
      thumb.addClass('selected');
      entity.find('.main-image img').attr('src', newImg);
      entity.find('.main-image img').attr('data-zoomable', newImg.replace('product', 'original'));
      entity.find('.main-image a').attr('href', newImg);
      return entity.find(".main-image").data('selectedThumb', newImg);
    }
  };

  toggle_personalisation_option_value = function(entity, element, event) {
    var personalisation, selected_presentation, selected_type, selected_value;
    event.preventDefault();
    personalisation = element.parents('.personalisation');
    selected_type = element.data('type');
    selected_value = element.data('value');
    selected_presentation = element.data('presentation');
    if (selected_type === 'colour') {
      personalisation.find("span.personalisation-color-value").text(selected_presentation);
      personalisation.find('.hidden.personalisation-colour').val(element.data('id'));
    }
    if (personalisation.find(".personalisation-option-value." + selected_type + "." + selected_value).hasClass('unavailable')) {
      return false;
    }
    personalisation.find(".personalisation-option-value." + selected_type).removeClass('selected');
    return personalisation.find(".personalisation-option-value." + selected_type + "." + selected_value).addClass('selected');
  };

  toggle_personalisations = function(entity, checkbox, event) {
    var personalisation, personalisation_id, thumb, thumbs;
    personalisation = checkbox.parents('.personalisation');
    personalisation_id = checkbox.val();
    thumbs = entity.find("ul.thumbnails li.tmb-personalisation-" + personalisation_id);
    if (checkbox.is(':checked')) {
      if (thumbs.length > 0) {
        thumbs.show();
        thumb = thumbs.first();
        change_main_image(entity, thumb);
      }
      personalisation.find('.personalisation-options').show();
      return personalisation.find('.personalisation-option-values').show();
    } else {
      if (thumbs.length > 0) {
        thumbs.hide();
        thumb = entity.find("ul.thumbnails li.vtmb:visible").first();
        change_main_image(entity, thumb);
      }
      personalisation.find('.personalisation-options').hide();
      return personalisation.find('.personalisation-option-values').hide();
    }
  }
  //////aasdasdsadsadasdasd
  function bottomPart(){
    var format_price, sum_of_optional_part_prices;
    entity.find('.row-assembly .option-value').click(function(event) {
      var main_image, option_value, option_values, part_id, presentation_spans, product_variants, selected_option_values, selected_parts, selected_presentation, thumb_href, thumbs, tree, variant;
      event.preventDefault();
      option_value = $(this);
      selected_presentation = option_value.data('presentation');
      option_values = option_value.closest('.variant-option-values');
      product_variants = option_values.closest('.product-variants');
      if (option_value.hasClass('unavailable')) {
        return false;
      }
      thumbs = entity.find('ul.thumbnails li.tmb-product-parts');
      thumbs.show();
      thumb_href = thumbs.first().find('a').attr('href');
      main_image = entity.find('.main-image');
      main_image.find('img').attr('src', thumb_href);
      main_image.find('a').attr('href', thumb_href);
      option_values.find('.option-value').removeClass('selected');
      option_value.closest('.variant-options').addClass('selected');
      option_value.addClass('selected');
      presentation_spans = product_variants.find('span:not(.optional)');
      if (core.isMobileWidthOrLess() === false) {
        presentation_spans.eq(0).text(selected_presentation);
      } else {
        presentation_spans.not(".mobile-product-presentation").eq(0).text(selected_presentation);
      }
      tree = product_variants.data('tree');
      selected_option_values = product_variants.find('.option-value.selected').each(function() {
        var selected_type, selected_value;
        selected_type = $(this).data('type');
        selected_value = $(this).data('value');
        if (selected_type in tree) {
          if (selected_value in tree[selected_type]) {
            return tree = tree[selected_type][selected_value];
          }
        }
      });
      part_id = product_variants.data('adp-id');
      if ('variant' in tree) {
        variant = tree['variant'];
        product_variants.find('.selected-parts').val(variant['id']);
        product_variants.data('adjustment', variant['part_price']);
        if (variant['image_url']) {
          $('.part-image-' + part_id).css('background-image', 'url(' + variant['image_url'] + ')');
        }
      } else {
        $('.part-image-' + part_id).css('background-image', 'none');
        selected_parts = product_variants.find('.selected-parts');
        selected_parts.val(selected_parts.data('original-value'));
        product_variants.data('adjustment', 0);
      }
      entity.find(".price").trigger('recalculate');
      entity.find(".prices").trigger('update');
      entity.find(".add-to-cart-button").trigger('update');
      return core.suite.setAssemblyListHeights();
    });
    entity.find(".prices").on('update', (function() {
      if (entity.find('.variant-options.required:not(.selected)').length > 0) {
        return $(this).find('.price').addClass('unselected');
      } else {
        return $(this).find('.price').removeClass('unselected');
      }
    }));
    entity.find(".price").on('recalculate', (function() {
      var adjustment;
      adjustment = sum_of_optional_part_prices(entity);
      return $(this).html(format_price($(this).data('currency'), $(this).data('price') + adjustment));
    }));
    format_price = function(currencySymbol, pence) {
      return "" + currencySymbol + ((pence / 100).toFixed(2));
    };
    sum_of_optional_part_prices = function(entity) {
      var sum;
      sum = 0;
      entity.find(".product-variants.optional").each(function() {
        return sum = sum + (Number($(this).data('adjustment') * $(this).data('quantity')));
      });
      return sum;
    };
    entity.find(".add-to-cart-button").on('update', (function() {
      if (entity.find('.variant-options.required:not(.selected)').length > 0) {
        return $(this).attr("style", "opacity: 0.5").addClass('disabled tooltip');
      } else {
        return $(this).removeAttr("style").removeClass("disabled tooltip");
      }
    }));

    entity.find('.add-to-cart-button').click(function(event) {
      if ($(this).hasClass('disabled')) {
        return false;
      }
    });
  }
  topPart();
  bottomPart();

};
