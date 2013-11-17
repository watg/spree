class ProductPageVariant
    constructor: (variant_id) ->
        @elem = $("#variant-#{variant_id}")
        top = @elem.closest("section.product-type")
        @displayedTable = top.find(".displayed table")
        @emptyMessage = @displayedTable.find("tr.empty")
        @availableTable = top.find(".available table")

    disable: ->
        @elem.detach()
        if @displayedTable.find(".variant").length == 0
            @emptyMessage.show()
        @availableTable.append(@elem)
        @elem.find(".sort").hide()

new ProductPageVariant("<%= @variant_id %>").disable()
