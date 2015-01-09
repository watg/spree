jQuery ->
  $('.stock_item_backorderable').on 'click', ->
    $(@).parent('form').submit()
  $('.toggle_stock_item_backorderable').on 'submit', ->
    $.ajax
      type: @method
      url: @action
      data: $(@).serialize()
    false
  $('.adjust_count_on_hand_link').on 'click', ->
    item_id =  $(this).data('stock-item-id')
    $(".adjust_count_on_hand.stock_item-#{item_id}").submit()
    false
