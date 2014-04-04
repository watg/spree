core.olapicGallery = {};

core.olapicGallery.apiUrl = 'http://api.photorank.me/v1/photos';
core.olapicGallery.proxyUrl = '/shop/oproxy'
core.olapicGallery.streamId;

$(document).ready(function() {
	if (!$('body').hasClass('olapic-gallery')) return false;

	core.olapicGallery.setStreamId();
	core.olapicGallery.getStreamData();
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
			stream: core.olapicGallery.streamId
			//offset: 20
			//limit: 20
		},
		success: function(response) {
			core.olapicGallery.processStreamData(response.response);
		}
	});
}

/* ----- Non-init methods ----- */

core.olapicGallery.getStreamId = function() {
	return $('.row-olapic-gallery').attr('data-stream-id');
}

core.olapicGallery.processStreamData = function(response) {
	if (response.code != 0 || response.length == 0) return false; // Die if no photos in stream
	
	$.each(response, function(id, photo) {
		core.olapicGallery.addPhotos(id, photo);
		core.olapicGallery.addModals(id, photo);
		core.resetModals();
		core.readyModals();
	});
}

// Add photos to the page
core.olapicGallery.addPhotos = function(id, data) {
	var container = $('.row-olapic-gallery > div');
	
	var item = '<li><a rel="modal" href="#modal-' + id + '">More about photo ' + id + '</a></li>';
	if (id % 5 === 0) { // Every fifth item
		if (id % 2 === 0) { // Even
			container.append('<ul class="no-bullet even"></ul>');
		} else { // Odd
			container.append('<ul class="no-bullet odd"></ul>');
		}
	}
	
	container.find('ul:last').append(item);
	container.find('li').eq(id).css('background-image', 'url(' + data.normal_image + ')');
}

// Add modals to the page
core.olapicGallery.addModals = function(id, data) {
	var row = $('.row-olapic-gallery');
	
	var modal = $('<div class="modal" id="modal-' + id + '"></div>');
	modal.append('<a class="modal-close" href="#">Close</a>');
	
	modal.insertAfter(row);
}