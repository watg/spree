class ProductPageVariant
    constructor: (variant_id) ->
        @elem = $("#variant-#{variant_id}")
        top = @elem.closest("section.product-type")
        @displayedTable = top.find(".displayed table")
        @emptyMessage = @displayedTable.find("tr.empty")
        @availableTable = top.find(".available table")

    enable: ->
        @elem.detach()
        @emptyMessage.hide()
        @displayedTable.append(@elem)
        @elem.find(".sort").show()

new ProductPageVariant("<%= @variant_id %>").enable()
