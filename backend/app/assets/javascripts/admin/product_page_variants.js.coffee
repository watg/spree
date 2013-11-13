class ProductPageVariant
    constructor: (@list, @elem) ->
        @elem.find("input.display-toggle").change (event) =>
            target = event.target
            @elem.detach()
            if $(target).prop("checked")
                @list.moveToDisplayed(@elem)
            else
                @list.moveToAvailable(@elem)

class ProductTypeList
    constructor: (selector) ->
        @elem = $(selector)
        @displayedTable = @elem.find(".displayed table")
        @displayedTableEmpty = @displayedTable.find("tr.empty")
        if @displayedTable.find("tbody tr").length != 1
            @displayedTableEmpty.detach()
        @availableTable = @elem.find(".available table")

        @elem.find("tr.variant").each (_, elem) =>
            new ProductPageVariant(@, $(elem))

    moveToDisplayed: (tr) ->
        @displayedTableEmpty.detach()
        @displayedTable.append(tr)

    moveToAvailable: (tr) ->
        @availableTable.append(tr)
        if @displayedTable.find("tbody tr").length == 0
            @displayedTable.append(@displayedTableEmpty)

$ ->
    $("section.product-type").each ->
        new ProductTypeList(@)
