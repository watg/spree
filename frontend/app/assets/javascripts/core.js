core = {}; // Extend from this core object

var readyCore = function() {
	core.readyModals();
	core.readyTooltips();
	core.readyAccordions();
	core.readyCarousels();
	core.showCookieMessage();
	core.readyAlpacaAttack();
};

$(document).ready(readyCore);
$(document).on('page:load', readyCore);
  
// On document fully loaded...
$(window).bind('load', function() {
  if ($('body').hasClass('no-sitewide-promo')) return false; // Die if sitewide promo not required
  setTimeout(function() { core.signupCheck() }, 4000);
});

/* ----- Init methods ----- */

// Ready modal plugin
core.readyModals = function() {
	$('a[rel*=modal]').leanModal({top: 30, closeButton: '.modal-close'});

	// Prime additional 'close modal' CTA...
	$('.modal .button:not(.no-close)').on('click', function(e) {
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
  if (core.isMobileWidthOrLess()) return false; // Die if mobile

  $('#nav-bar .worldwide').on('click', function(e) {
	core.resetAlpacaAttack();
    core.runAlpacaAttack();
  });
}

/* Check for sign-up cookie. No sign-up cookie = display sign-up. Yes sign-up cookie = display pattern */
core.signupCheck = function() {
  var cookie = core.signupGetCookie();
  if (!cookie) { // No sign-up cookie
    core.signupUser();
    $('.link-modal-signup').click();
    core.signupSetCookie();
  } else { // Yes sign-up cookie
    cookie = core.patternsGetCookie();
    if (!cookie && !core.isMobileWidthOrLess()) { // Yes pattern cookie
      $('.link-modal-patterns').click();
      core.patternsSetCookie();
    }
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
  var test = $(window).width() <= 460 ? true : false;
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

// Animation for alpaca attack
core.runAlpacaAttack = function() {

  // lining up the army of alpacas
  var normalPosition = {
    transform: 'none',
    left: '-150px',
    top: 0,
    leftanimate: '+=150px',
    leftanimateend: '-=150px',
    topanimate: 'none',
    topanimateend: 'none'};

  var lowerPosition = {
    transform: 'none',
    left:'-150px',
    top: '400px',
    leftanimate: '+=150px',
    leftanimateend: '-=150px',
    topanimate: 'none',
    topanimateend: 'none'};

  var rotatedSide ={
    transform: 'rotate(90deg)',
    left: '-500px',
    top: '0',
    leftanimate: '+=450px',
    leftanimateend: '-=450px',
    topanimate: 'none',
    topanimateend: 'none'};

  var rotatedTop = {
    transform: 'rotate(180deg)',
    left: '200px',
    top: '-500px',
    leftanimate: '200px',
    leftanimateend: '200px',
    topanimate: '+=250px',
    topanimateend: '-=500px'};

  var middleTop = {
    transform: 'rotate(180deg)',
    left: '800px',
    top: '-500px',
    leftanimate: '800px',
    leftanimateend: '800px',
    topanimate: '+=250px',
    topanimateend: '-=500px'};

  // choosing tributes from the army of alpacas
  var alpaca = $('.alpaca-attack');
  var alpacas = [middleTop, rotatedTop, rotatedSide, lowerPosition, normalPosition];
  var random_alpaca = alpacas[Math.floor(Math.random() * alpacas.length)];

  // sending the aplaca off to do its mission
  alpaca.css({
      'display': 'initial',
      'transform': random_alpaca.transform,
      'left': random_alpaca.left,
      'top': random_alpaca.top
    });
  alpaca.animate({
    left: random_alpaca.leftanimate,
    top: random_alpaca.topanimate
  }, 1000);
  alpaca.animate({
    left: random_alpaca.leftanimateend,
    top: random_alpaca.topanimateend
  }, 250);
};

// Reset animation for alpaca attack
core.resetAlpacaAttack = function() {
	var alpaca = $('.alpaca-attack');
	alpaca.stop(true, true);
	alpaca.css({
		'display': 'none',
		'top': 0,
		'left': 0
	});
}

core.signupUser = function() {
  var modal = $('#modal-signup');
  var form = modal.find('form');
  var heading_primary = modal.find('h3');
  var heading_secondary = modal.find('h4');
  var disclaimer = modal.find($('.disclaimer'));

  form.on('submit', function(e) {
    e.preventDefault();
    // Die if no value
    if (!form.find('input[name="signupEmail"]').val()) return false;
    form.fadeOut('slow');
    heading_primary.fadeOut('slow');
    heading_secondary.fadeOut('slow');
    disclaimer.fadeOut('slow');
    $.ajax({
      type: 'POST',
      url: form.attr('action'),
      data: form.serialize(),
      dataType: 'json',
      success: function(e) {
        if (e.response !== 'success') {
          heading_primary.text('Oops, sorry!');
          heading_secondary.text("Something's gone wrong, please try again:");
          form.fadeIn('slow')
        } else {
          heading_primary.text("Yippee!");
          heading_secondary.html(core.signupGetPromoText);
          // $('<small>' + core.signupGetPromoDisclaimer() + '</small>').insertAfter(form);
          $('<p class="promo-code">' + core.signupGetPromoCode() + '</p>').insertAfter(form);
          core.signupSetCookie();
        }
        disclaimer.fadeIn('slow');
        heading_primary.fadeIn('slow');
        heading_secondary.fadeIn('slow');
      }
    })
  })
}

core.signupSetCookie = function() {
  $.cookie('signupPopKilled', 'true', {expires: 365, path: '/'});
}

core.signupGetCookie = function() {
  return $.cookie('signupPopKilled');
}

core.patternsSetCookie = function() {
  $.cookie('patternPopKilled', 'true', {expires: 365, path: '/'});
}

core.patternsGetCookie = function() {
  return $.cookie('patternPopKilled');
}

core.signupGetPromoCode = function() {
  return 'G9XrwE3056';
}

core.signupGetPromoText = function() {
  return '<strong>Get 10% off</strong> your items,<br/>Enter code when you check out:';
}

// optional, depending where veronica wants the disclaimer
core.signupGetPromoDisclaimer = function() {
  return 'Available only until October 21st';
}