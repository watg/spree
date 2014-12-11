jQuery ->
  $('form.edit_suite').on 'click', '.remove_tab', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('.suite_tab').hide()
    event.preventDefault()

  $('form.edit_suite').on 'click', '.add_tab', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $('#suite_tabs').append($(this).data('fields').replace(regexp, time))
    $('#suite_tabs').children().last().find('.product_autocomplete').productAutocompleteSingle()
    activateSelect2()
    event.preventDefault()

  $('a.remove_image').on 'click', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).parent().parent().find('img').hide()
    $(this).text("The image will be deleted after update")
    event.preventDefault()

  $('.s3_uploader_form').each ->
    $(this).S3Uploader(
      {
        before_add: alertIfSmallerThan1MB,
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
  product_group.productGroupAutocomplete()


alertIfSmallerThan1MB = (file) ->
  if (file.size < Math.pow(2,20) )
    alert("carefull! it looks like that image may be too small, make sure you check it is not blurry")

  # we only want to give a warning and not disallow the image upload
  true
