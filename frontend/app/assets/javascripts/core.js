core = {}; // Extend from this core object

$(document).ready(function() {
	core.readyNavigation();
	core.readyNavigationMobile();
	core.readyModals();
	core.readyTooltips();
	core.readyAccordions();
	core.readyCarousels();
	core.showCookieMessage();
	core.readyAlpacaAttack();

/* ----- Init methods ----- */

// Ready primary navigation
core.readyNavigation = function() {
	if (Modernizr.touch) {
		// ----- Tablet
		$('.nav-primary li').bind('touchstart', function(e) {
			if ($(this).children('a').hasClass('active')) {
				return true;
			} else {
				e.preventDefault();
				core.showSubNavigation($(this));
			}
		});
	} else { 
		// ----- Desktop 
		$('.nav-primary li').on({
			mouseover: function() {
				core.showSubNavigation($(this));
			},
			mouseout: function() {
				core.hideSubNavigation($(this));
			}
		});
		$('.nav-primary-sub').on({
			mouseover: function() {
				$(this).addClass('expanded');
			},
			mouseout: function() {
				$(this).removeClass('expanded');
			}
		});
	}
};

// Ready primary navigation for mobile
core.readyNavigationMobile = function() {
	$('.link-nav-primary-sub').on({
		click: function(e) {
			e.preventDefault();
			core.showSubNavigationMobile();
		}
	});
};

// Show sub primary navigation
core.showSubNavigation = function(e) {
	$('.nav-primary li a').removeClass('active') 
	// Needed for tablet

	e.children('a').addClass('active');

	$('.nav-primary-sub').addClass('expanded');
	$('.nav-primary-sub .columns').show();
	$(".nav-primary-sub [class$='-sub']").hide();

	var sub_id = '.' + e.attr('class') + '-sub';
	$(sub_id).show();
};

// Show sub primary navigation for mobile
core.showSubNavigationMobile = function(e) {
	$('.nav-primary-sub').toggleClass('expanded');
	$(".nav-primary-sub [class$='-sub']").show();
	$('.nav-primary-sub .columns').not('.small-12').hide();
};

// Hide sub primary navigation
core.hideSubNavigation = function(e) {
	e.children('a').removeClass('active');
	
	$('.nav-primary-sub').removeClass('expanded');
};

// Ready modal plugin
core.readyModals = function() {
	$('a[rel*=modal]').leanModal({top: 30, closeButton: '.modal-close'});
	
	// Prime additional 'close modal' CTA...
	$('.modal .button').on('click', function(e) {
		e.preventDefault();
		$(this).parent().siblings('.modal-close').click();
	});
};

// Reset modal events
core.resetModals = function() {
	$('a[rel*=modal]').off();
	
	$('.modal .button').off();
};

// Ready tooltips plugin
core.readyTooltips = function() {
    $('.tooltip').tooltipster({ delay: 0
	});
};

core.readyAccordions = function() {
    $('.accordion-content').hide();
    $('.accordion-title').on('click', function() {
        $(this).next().slideToggle();
    });
}

core.showCookieMessage = function() {
	var name = 'showCookieMessage';

	if (!$.cookie(name)) {
		var row = $('.row-cookie');
		
		row.fadeIn('slow');
		row.find('a:first').on('click', function(e) {
			e.preventDefault();
			$.cookie(name, 'true', {expires: 365, path: '/'});
			row.fadeOut('slow');
		});
	}
};

core.readyCarousels = function() {

  if (core.isMobileWidthOrLess() === true) {
    // Carousel initialization
  $('.jcarousel')
      .jcarousel({
          // Options go here
      });

  /*
   Prev control initialization
   */
  $('.jcarousel-control-prev')
      .on('jcarouselcontrol:active', function() {
          $(this).removeClass('inactive');
      })
      .on('jcarouselcontrol:inactive', function() {
          $(this).addClass('inactive');
      })
      .jcarouselControl({
          // Options go here
          target: '-=1'
      });

  /*
   Next control initialization
   */
  $('.jcarousel-control-next')
      .on('jcarouselcontrol:active', function() {
          $(this).removeClass('inactive');
      })
      .on('jcarouselcontrol:inactive', function() {
          $(this).addClass('inactive');
      })
      .jcarouselControl({
          // Options go here
          target: '+=1'
      });
  }  
}

// Attach event handler for alpaca attack
core.readyAlpacaAttack = function() {
	$('#nav-bar .worldwide').on('click', function(e) {
	 core.runAlpacaAttack();
  });
};

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

/* Check for a valid email address */
core.isEmail = function(email) {
	return /^([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22))*\x40([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d))*$/.test(email);
}
};

// Animation for alpaca attack
core.runAlpacaAttack = function() {
  $('.alpaca-attack').css('display', 'block');
      $('.alpaca-attack').animate({height: 'toggle'});
      $('.alpaca-attack').animate({width: 'toggle'});
};
