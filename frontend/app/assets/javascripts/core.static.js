core.Static = {}; // Extend from this core object

$(document).ready(function() {
  if (!$('body').hasClass('static')) return false;

  if ($('body').hasClass('knit-party')) {
    core.Static.readyscrolltoForm();
    core.Static.readyscrolltoInfo();
  };


  if ($('body').hasClass('vote-for-your-favourite')) {
    core.Static.randomiseBackgroundPosition();
  };



});

// runs to form and info
core.Static.readyscrolltoForm = function() {
  document.getElementById("become-a-host").onclick = function(e) {
    e.preventDefault()
    $.scrollTo($('.signup-form'), 500, {axis: 'y', easing: 'swing'});
  }
}

core.Static.readyscrolltoInfo = function() {
  document.getElementById("find-out-more").onclick = function(e) {
    e.preventDefault()
    $.scrollTo($('.info-first'), 500, {axis: 'y', easing: 'swing'});
  }
}


// Set a random background position (x-axis)
core.Static.randomiseBackgroundPosition = function() {
 var x_positions = ['-300px', '0', '300px'];
 var rand_num = Math.floor((Math.random() * x_positions.length));
 $('.row-hero').css('background-position', x_positions[rand_num] + ' 0');
}

