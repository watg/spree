core.Navigation = {}; 

$(document).on("ready page:load", function() {
  core.Navigation.readyNavigation();
  core.Navigation.readyNavigationMobile();
  core.Navigation.readyFooterMobile();
  core.Navigation.readyTracking();
});


core.Navigation.readyNavigation = function() {
  if (Modernizr.touch) {
    // ----- Tablet
    $('.nav-primary li').bind('touchstart', function(e) {
      if ($(this).children('a').hasClass('active')) {
        return true;
      } else {
        e.preventDefault();
        core.Navigation.showSubNavigation($(this));
      }
    });
  } else {
    // ----- Desktop
    $('.nav-primary li').on({
      mouseover: function() {
        core.Navigation.showSubNavigation($(this));
      },
      mouseout: function() {
        core.Navigation.hideSubNavigation($(this));
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

// Hide sub primary navigation
core.Navigation.hideSubNavigation = function(e) {
  e.children('a').removeClass('active');

  $('.nav-primary-sub').removeClass('expanded');
};

// Show sub primary navigation
core.Navigation.showSubNavigation = function(e) {
  $('.nav-primary li a').removeClass('active')
  // Needed for tablet

  e.children('a').addClass('active');

  $('.nav-primary-sub').addClass('expanded');
  $('.nav-primary-sub .columns').show();
  $(".nav-primary-sub [class$='-sub']").hide();

  var sub_id = '.' + e.attr('class') + '-sub';
  $(sub_id).show();
};

// Ready primary navigation for mobile
core.Navigation.readyNavigationMobile = function() {
  $('.link-nav-primary-sub').on({
    click: function(e) {
      e.preventDefault();
      core.Navigation.showSubNavigationMobile();
    }
  });
};

// Show sub primary navigation for mobile
core.Navigation.showSubNavigationMobile = function(e) {
  $('.nav-primary-sub').toggleClass('expanded');
  $(".nav-primary-sub [class$='-sub']").show();
  $('.nav-primary-sub .columns').not('.small-12').hide();
  core.Navigation.showSecondarySubNavigationMobile();
};

core.Navigation.showSecondarySubNavigationMobile = function(e) {
  var sub_menus = $('.sub-menu');

  sub_menus.on({
    click: function(e) {
    e.preventDefault();
      // Close all others first...
      sub_menus.not(this).closest('li').removeClass('expanded').addClass('hidden');

      // Open this one
      var dropdown = $(this).closest('li');
      dropdown.toggleClass('hidden');
      dropdown.toggleClass('expanded');
    }
  });
};

core.Navigation.readyFooterMobile = function() {
   $('.more-footer').on({
    click: function(e) {
      e.preventDefault();
      core.Navigation.showSubFooterMobile();
    }
  });
}

core.Navigation.showSubFooterMobile = function(e) {
  $('.dropdown').toggleClass('hidden');
  $('.dropdown').toggleClass('expanded');
  $('.more-footer').toggleClass('button-normal');
  $('.more-footer').toggleClass('button-inverse');

  if ($('.more-footer').hasClass('button-inverse')) {
    $('.button-inverse').text('Less -');
  };

  if ($('.more-footer').hasClass('button-normal')) {
    $('.button-normal').text('More +');
  };

  $.scrollTo($('.mobile-raf'), 500, {axis: 'y', easing: 'swing'});
}

core.Navigation.readyTracking = function() {
  var links = $('.nav-primary, .nav-primary-sub').find('a');
  links.on({
    click: function(e) {
      // Stop
      e.preventDefault();

      // Get the data path, or just pass link name in its absence
      var path = $(this).data('path');
      var event_path = path == undefined ? $(this).text().toLowerCase() : path;

      // Track
      if (typeof ga !== 'undefined') {
        ga('send', 'event', 'navigation', 'click', event_path);
      }

      // Continue
      location.href = $(this).attr('href');
    }
  });
}