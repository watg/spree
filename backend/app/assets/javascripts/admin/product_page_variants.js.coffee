$ ->
    $(".variant input.display-toggle").change (event) ->
        target = $(event.target)
        variant = target.closest(".variant")
        id = variant.data('variant-id')
        if target.is(':checked')
            $.ajax Spree.routes.product_page_variants,
                type: 'POST'
                data: { variant_id: id }
                dataType: "script"
                error: (xhr) ->
                    target.removeAttr('checked')
                    show_flash_error(xhr.responseText)
        else
            $.ajax Spree.routes.product_page_variants + "/" + id,
                type: 'DELETE'
                dataType: "script"
                error: (xhr) ->
                    target.attr('checked', true)
                    show_flash_error(xhr.responseText)


  $("table.variants.displayed tbody").ready ->
    $("table.variants.displayed tbody").sortable
        handle: '.handle'
        update: (event, ui) ->
            tbody = $(ui.item).closest("tbody")
            positions = {}
            for variant, idx in tbody.find(".variant")
                id = $(variant).attr('id').replace(/variant-/, '')
                positions[id] = idx
            $("#progress").show()
            $.ajax Spree.routes.update_positions_product_page_variants,
                type: "POST"
                dataType: 'script'
                data: { positions: positions }
                complete: (-> $("#progress").hide())
