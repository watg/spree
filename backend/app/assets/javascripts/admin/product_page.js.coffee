jQuery ->
  $('.s3_uploader_form').each ->
    $(this).S3Uploader(
      { 
        remove_completed_progress_bar: false,
        allow_multiple_files: false,
        progress_bar_target: $('#uploads_container')
      }
    )

    $(this).bind 's3_upload_failed', (e, content) ->
      alert(content.filename + ' failed to upload')
