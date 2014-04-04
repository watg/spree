core.olapicGallery = {};

core.olapicGallery.apiUrl = 'http://api.photorank.me/v1/photos';
core.olapicGallery.proxyUrl = '/shop/oproxy';
core.olapicGallery.streamOffset = 0;
core.olapicGallery.streamId;

$(document).ready(function() {
	if (!$('body').hasClass('olapic-gallery')) return false;

	core.olapicGallery.setStreamId();
	core.olapicGallery.getStreamData();
	core.olapicGallery.readyMoreButton();
});

/* ----- Init methods ----- */

core.olapicGallery.setStreamId = function() {
	core.olapicGallery.streamId = core.olapicGallery.getStreamId();
}

core.olapicGallery.getStreamData = function() {
	$.ajax({
		url: core.olapicGallery.proxyUrl,
		dataType: 'json',
		data: {
			url: core.olapicGallery.apiUrl,
			stream: core.olapicGallery.streamId,
			offset: core.olapicGallery.streamOffset
			//limit: 20
		},
		success: function(response) {
			core.olapicGallery.processStreamData(response);
		}
	});
}

core.olapicGallery.readyMoreButton = function() {
	$('.button').on('click', function(e) {
		e.preventDefault();
		core.olapicGallery.getStreamData();
	});
}

/* ----- Non-init methods ----- */

core.olapicGallery.getStreamId = function() {
	return $('.row-olapic-gallery').attr('data-stream-id');
}

core.olapicGallery.processStreamData = function(response) {
	var code = response.code;
	var data = response.response;
	
	if (code != 0 || data.length == 0) return false; // Die if error or no photos in stream
		
	$.each(data, function(id, photo) {
		core.olapicGallery.addPhoto(id, photo);
		core.olapicGallery.addModal(id, photo);
		core.resetModals();
		core.readyModals();
	});
	
	core.olapicGallery.streamOffset += data.length;
}

// Add photo to the page
core.olapicGallery.addPhoto = function(id, data) {
	var container = $('.row-olapic-gallery > div');
	var para = $('.row-olapic-gallery > div p');
	
	var item = '<li class="' + data.id + '"><a rel="modal" href="#modal-' + data.id + '">More about photo ' + data.id + '</a></li>';
	if (id % 5 === 0) { // Every fifth item
		if (id % 2 === 0) { // Odd ('cos human beans count from one, not zero)
			$('<ul class="no-bullet odd"></ul>').insertBefore(para);
		} else { // Even
			$('<ul class="no-bullet even"></ul>').insertBefore(para);
		}
	}
	
	container.find('ul:last').append(item);
	container.find('li.' + data.id).css('background-image', 'url(' + data.normal_image + ')');
}

// Add modal to the page
core.olapicGallery.addModal = function(id, data) {
	var row = $('.row-olapic-gallery');
	var modal = $('<div class="modal" id="modal-' + data.id + '"></div>');
	
	modal.append('<a class="modal-close" href="#">Close</a>');
	modal.append('<div class="col-left"></div>');
	modal.append('<div class="col-right"><h3><a href="' + data.original_source + '">' + data.user_name + '</a></h3><p>' + data.caption + '</p></div>');
	modal.insertAfter(row);
	
	$('#modal-' + data.id + ' .col-left').css('background-image', 'url(' + data.normal_image + ')');
}