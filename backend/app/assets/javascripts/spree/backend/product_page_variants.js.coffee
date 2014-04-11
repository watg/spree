$ ->
    $(".variant input.display-toggle").change (event) ->
        target = $(event.target)
        variant = target.closest(".variant")
        id = variant.data('variant-id')
        url = variant.data("url")
        if target.is(':checked')
            $.ajax url,
                type: 'POST'
                data: { variant_id: id }
                dataType: "script"
                error: (xhr) ->
                    target.removeAttr('checked')
                    show_flash_error(xhr.responseText)
        else
            $.ajax url + "/" + id,
                type: 'DELETE'
                dataType: "script"
                error: (xhr) ->
                    target.attr('checked', true)
                    show_flash_error(xhr.responseText)


  $("table.variants.displayed tbody").ready ->
    for table in $("table.variants.displayed")
        url = $(table).data("url")
        $(table).find("tbody").sortable
            handle: '.handle'
            update: (event, ui) ->
                tbody = $(ui.item).closest("tbody")
                positions = {}
                for variant, idx in tbody.find(".variant")
                    id = $(variant).data('variant-id')
                    positions[id] = idx
                $("#progress").show()
                $.ajax url,
                    type: "POST"
                    dataType: 'script'
                    data: { positions: positions }
                    complete: (-> $("#progress").hide())
