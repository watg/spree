core.Static = {}; // Extend from this core object

$(document).on('ready page:load', function() {
  if (!$('body').hasClass('static')) return false;

  if ($('body').hasClass('vote-for-your-favourite')) {
    core.Static.randomiseBackgroundPosition();
  };

	if ($('body').hasClass('careers')) {
		core.Static.showJobFromHash();
	};

  if ($('body').hasClass('carousel')) {
    core.Static.readyCarousel();
  };

  if ($('body').hasClass('signup-carousel')) {
    core.Static.readySignupCarousel();
  };

  if ($('body').hasClass('fancyboxmodal')) {
    core.Static.fancyboxModal();
  };

  if ($('body').hasClass('hang-with-the-gang')) {
    core.Static.readyOlapicGallery();
  }
});

$(window).bind('load', function() {

});

// Set a random background position (x-axis)
core.Static.randomiseBackgroundPosition = function() {
 var x_positions = ['-300px', '0', '300px'];
 var rand_num = Math.floor((Math.random() * x_positions.length));
 $('.row-hero').css('background-position', x_positions[rand_num] + ' 0');
}

core.Static.showJobFromHash = function() {
	var hash = window.location.hash.toString();

	if (hash.length > 0) {
		var job_id = $(hash);
		if (job_id) {
			job_id.click();
			window.location.href = hash;
		}
	}
}

core.Static.readyCarousel = function() {
   $('.owl-carousel').owlCarousel({
    loop:true,
    responsiveClass:true,
    responsive:{
      0:{
        items:1,
        nav:true
      },
      700:{
        items:3,
        nav:true,
      }
    }
  });
}

core.Static.readyOlapicGallery = function() {
  OlapicWidget({
    'id': '51215f5af67327b835d902d720009f06',
    'wrapper': 'olapic_specific_widget'
  });
};

core.Static.readySignupCarousel = function() {
  // sets correct arrow images
  var left_owl = document.getElementsByClassName('owl-prev');
  var left = new Image();
  var right_owl = document.getElementsByClassName('owl-next');
  var right = new Image();
  left.onload = function() {
    left_owl[0].appendChild(left);
  };
  right.onload = function() {
    right_owl[0].appendChild(right);
  };
  left.src = 'https://s3-eu-west-1.amazonaws.com/assetswoolandthegangcom/static/free-knitting-patterns/free-patterns-arrow-left-thin.jpg';
  left.id = 'correct-left';
  right.src = 'https://s3-eu-west-1.amazonaws.com/assetswoolandthegangcom/static/free-knitting-patterns/free-patterns-arrow-right-thin.jpg';
  right.id = 'correct-right';

  // carousel settings
  $('.owl-carousel').owlCarousel({
    loop:true,
    responsiveClass:true,
    responsive:{
      0:{
        items:1,
        nav:true
      },
      700:{
        items:5,
        nav:true,
      }
    }
  });

}

core.Static.fancyboxModal = function() {
  $('.fancybox').fancybox();
    $('.fancybox-media')
    .fancybox({
      openEffect : 'none',
      closeEffect : 'none',
      helpers : {
      media : {}
    }
  });
}
