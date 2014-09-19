// TODO: Remove unused methods and move remaining to core

/* Site-wide WATG clientside scripts */
var WATG = window.WATG || {};

/* --- Sitewide signup starts --- */

WATG.signup = {
	globals: {
		cookie: 'signupPopKilled'
		// cookie: 'competition2014Killed'
	},

	init: function() {
		WATG.signup.globals.signupForms.on('submit', function(e) {
			var form = $(this);
			e.preventDefault();
			// Die if no value
			if (!$(this).find('input[name="signupEmail"]').val()) return false;
			form.fadeOut();
			$.ajax({
		    type: 'POST',
		    url: form.attr('action'),
		    data: form.serialize(),
		    dataType: 'json',
		    success: function(e) {
					var message_cont = WATG.signup.globals.responses.children('div');
					message_cont.html(e.message);
					// Switch off response conditional for promos. When we have a promo code to display, we don't mind if the user's already signed up.
					if (e.response !== 'success') {
						WATG.signup.showError();
					} else {
						message_cont.html(WATG.signup.getPromo);
						WATG.signup.setCookie();
					}
					WATG.signup.globals.responses.fadeIn();
				}
			})
		})
	},

	begin: function() {
		if (WATG.signup.getCookie() === 'true') {
			WATG.signup.globals.container.remove();
		} else {
			WATG.signup.globals.container.addClass('open');
			WATG.signup.globals.close.on('click', function(e) {
				e.preventDefault();
				WATG.signup.globals.container.addClass('no-delay').removeClass('open');
				WATG.signup.setCookie();
			});
		}
	},

	setCookie: function() {
		$.cookie(WATG.signup.globals.cookie, 'true', {expires: 365, path: '/'});
	},

	getCookie: function() {
		return $.cookie(WATG.signup.globals.cookie);
	},

	getPromo: function() {
		return '<p>Thanks for signing up.<br/>Enter code when you check out to get 15% off your order* :)<br/><strong>HELLO72X76</strong><br/><small>*Expires midnight 22nd September</small></p>';
	},

	showError: function() {
		var message_cont = WATG.signup.globals.responses.children('div');
		message_cont.append('<a class="tryAgain" href="#">(Try again?)</a>');
		$(".tryAgain").click(function(e) {
			e.preventDefault();
			WATG.signup.globals.responses.fadeOut(function () {
				WATG.signup.globals.signupForms.fadeIn();
			})
		})
	}
}

/* --- Sitewide signup ends --- */

/* --- Refer-your-friends starts --- */

WATG.referral = {
	globals: {},
	referralForm: null,

	init: function() {
		this.referralForm = $('#referralForm');

		this.referralForm.on('submit', function(e) {
			e.preventDefault();
			WATG.referral.hideError();
			if (WATG.referral.checkQualifies() === true) {
				WATG.referral.submitForms();
			} else {
				WATG.referral.showError();
			}
		});

		$('.add-a-friend').on('click', function(e) {
			e.preventDefault();
			WATG.referral.hideError();
			// Clone the first referee input and spit out after the last
			var referee = $('#refereeForm');
			referee.find('input:eq(2)').clone().val('').insertAfter(referee.find('input:last')).hide().fadeIn('slow');
			});
	},

	// Check qualifies
	checkQualifies: function() {

		var qualifies = true;

		// Referrer --------------------

		// Check referrer email valid
		var email_referrer = this.referralForm.find('input[name="referrerEmail"]').val();
		if (!email_referrer || !WATG.referral.isEmail(email_referrer)) {  // Is valid?
			qualifies = false;
		}

		// Referees --------------------

		// Check we've got valid referee emails...
		var num_referees = 0;
		var email_referees = [];

		this.referralForm.find('input[name="refereeEmails[]"]').each(function() {
		    var email_referee = $(this).val();
			// Ignore empty inputs
			if (!email_referee) return true;

			if (!WATG.referral.isEmail(email_referee)) { // Is valid?
				qualifies = false;
			} else if (email_referee == email_referrer) { // Matches referrer email?
				qualifies = false;
			} else {
				email_referees.push($(this).val());
				num_referees++;
			}
		});

		//... and they're all different...
		if (email_referees.length != $.unique(email_referees).length) {
			qualifies = false;
		}

		//... and at least three of them
		/*if (num_referees < 3) {
			qualifies = false;
		}*/

		return qualifies;
	},

	// Submit on forms
	submitForms: function() {

		var _gaq = _gaq || [];
		_gaq.push(['_trackEvent', 'competition sign up', 'sign up']); // GA event
		this.showWait();

		$.ajax({
	    type: 'POST',
	    url: this.referralForm.attr('action'),
	    data: this.referralForm.serialize(),
	    dataType: 'json',
	    success: function(e) {
				WATG.referral.showThanks();
				WATG.referral.addFacebookPixel();
			}
		})
	},

	showWait: function() {
		this.referralForm.find('fieldset').hide();
		$('.competition-info').hide(); // Optional
		$('.text-center').hide(); // Optional
		$('<p class="wait">Please wait...</p>').hide().insertAfter(this.referralForm).fadeIn('slow').focus();
	},

	showThanks: function() {
		$('p.wait').remove();
		// allows for different messages between competitions
		var message = this.referralForm.find('#success-message').html()
		$(message).hide().insertBefore(this.referralForm).fadeIn('slow').focus();

	},

	showError: function() {
		$('<p class="error"><strong>Oops. Something\'s not quite right.</strong> <br/>Please check that you\'ve supplied your own email address, and check your friends addresses are all unique. Thank you!</p>').hide().insertBefore(this.referralForm).fadeIn('slow').focus();
		this.referralForm.find('input[type="email"]').css('border', '2px solid #f4bfbf');
	},

	hideError: function() {
		$('p.error').remove();
		this.referralForm.find('input[type="email"]').css('border', '1px solid #dadada');
	},

	/* Utility function. Move this out at some point... */
	isEmail: function(email) {
		return /^([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22))*\x40([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d))*$/.test(email);
	},

	addFacebookPixel: function() {
		$('<img/>').attr('src', 'https://www.facebook.com/tr?ev=6014728651499&amp;cd[value]=0.00&amp;cd[currency]=USD').appendTo('body');
	}
}

/* --- Refer your friends ends --- */

/* --- */

// On document ready...
$(function() {
    // FAQ togglers
    $('.faq-content').hide();
    $('.faq-title').on('click', function() {
        $(this).next().slideToggle();
    });

	// Career togglers
    $('.career-content').hide();
    $('.career-title').on('click', function() {
        $(this).parent().next().slideToggle();
    });

	// Refer-your-friends competitions
	if ($('body').hasClass('competition-2014') ||
		$('body').hasClass('competition-beatkit') ||
		$('body').hasClass('competition-shopping-spree-apr-2014') ||
		$('body').hasClass('competition-summer-look-jun-2014') ||
		$('body').hasClass('competition-summer-bag-jun-2014') ||
		$('body').hasClass('free-patterns') ||
		$('body').hasClass('competition-bespoke-hat')) {
		WATG.referral.init();
	}

});

// On document fully loaded...
$(window).bind('load', function() {
	// Signup starts
	if ($('body').hasClass('no-sitewide-promo')) return false; // Die if sitewide promo not required

	WATG.signup.globals.signupForms = $('.signup-form');
	WATG.signup.globals.container = $('#signupPromo');
	WATG.signup.globals.responses = $('.signup-response');
	WATG.signup.globals.close = $('.signup-close');

	WATG.signup.init();
	WATG.signup.begin();
	// Signup ends
});
