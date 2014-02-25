core = {}; // TODO: Extend from this core script

$(document).ready(function() {
	core.showCookieMessage();
});

/* ----- Init methods ----- */

core.showCookieMessage = function() {
	var name = 'showCookieMessage';

	if (!$.cookie(name)) {
		var row = $('.row-cookie');
		
		row.fadeIn('slow');
		row.find('a').on('click', function(e) {
			e.preventDefault();
			$.cookie(name, 'true', {expires: 365, path: '/'});
			row.fadeOut('slow');
		});
	}
}

/* ----- Non-init methods ----- */

// Test for tablet width or less
core.isTabletWidthOrLess = function() {
	var test = $(window).width() <= 768 ? true : false;
	return test;
}

// Test for mobile width or less
core.isMobileWidthOrLess = function() {
	var test = $(window).width() <= 320 ? true : false;
	return test;
}

// Return current path as array
core.getUrlPathAsArray = function() {
	return window.location.pathname.split('/');
}