jQuery ->
  $('form.edit_product_page').on 'click', '.remove_image', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).parent().find('img').hide()
    $(this).hide()
    event.preventDefault()

  $('.s3_uploader_form').each ->
    $(this).S3Uploader(
      { 
        remove_completed_progress_bar: false,
        allow_multiple_files: false,
        progress_bar_target: $('#uploads_container'),
        drop_zone: $($(this).data('dropZone')),
        additional_data: { 
          tab_id: $(this).data('tab'),
          drop_zone: $(this).data('dropZone')
        }
      }
    )
    $(this).bind 's3_upload_failed', (e, content) ->
      alert(content.filename + ' failed to upload')

  product_group = $('#product_page_product_group_ids')
  marketing_types = $('#product_page_tabs_attributes_1_marketing_type_ids')
  console.log marketing_types.val()
  console.log product_group.val()
  product_group.productGroupAutocomplete()
  kit = $('#product_page_kit_id')
  kit.kitAutocomplete(product_group.val(), marketing_types.val())

  product_group.on 'change', ->
    kit.kitAutocomplete(product_group.val(), marketing_types.val())
