$(document).ready(function() {
  
  $(function() {
    $('#s3_uploader').S3Uploader(
      { 
        remove_completed_progress_bar: false,
        progress_bar_target: $('#uploads_container')
      }
    );

    $('#s3_uploader').bind('s3_upload_failed', function(e, content) {
      return alert(content.filename + ' failed to upload');
    });

    $('.update_all_images').click(function(event) {
      event.preventDefault();
      
      $('.edit_image').each(function() {
        $(this).submit();
      });
      
    });
  });

});