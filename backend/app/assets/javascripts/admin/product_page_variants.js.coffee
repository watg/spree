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

