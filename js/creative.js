(function($) {
  "use strict"; // Start of use strict

  // Smooth scrolling using jQuery easing
  $('a.js-scroll-trigger[href*="#"]:not([href="#"])').click(function() {
    if (location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') && location.hostname == this.hostname) {
      var target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
      if (target.length) {
        $('html, body').animate({
          scrollTop: (target.offset().top - 57)
        }, 1000, "easeInOutExpo");
        return false;
      }
    }
  });

  // Closes responsive menu when a scroll trigger link is clicked
  $('.js-scroll-trigger').click(function() {
    $('.navbar-collapse').collapse('hide');
  });

  // Activate scrollspy to add active class to navbar items on scroll
  $('body').scrollspy({
    target: '#mainNav',
    offset: 57
  });

  // Collapse Navbar
  var navbarCollapse = function() {
    if ($("#mainNav").offset().top > 100) {
      $("#mainNav").addClass("navbar-shrink");
    } else {
      $("#mainNav").removeClass("navbar-shrink");
    }
  };
  // Collapse now if page is not at top
  navbarCollapse();
  // Collapse the navbar when page is scrolled
  $(window).scroll(navbarCollapse);

  // Scroll reveal calls
  window.sr = ScrollReveal();
  sr.reveal('.sr-icons', {
    duration: 600,
    scale: 0.3,
    distance: '0px'
  }, 200);
  sr.reveal('.sr-button', {
    duration: 1000,
    delay: 200
  });
  sr.reveal('.sr-contact', {
    duration: 600,
    scale: 0.3,
    distance: '0px'
  }, 300);

  // Magnific popup calls
  $('.popup-gallery').magnificPopup({
    delegate: 'a',
    type: 'image',
    tLoading: 'Loading image #%curr%...',
    mainClass: 'mfp-img-mobile',
    gallery: {
      enabled: true,
      navigateByImgClick: true,
      preload: [0, 1]
    },
    image: {
      tError: '<a href="%url%">The image #%curr%</a> could not be loaded.'
    }
  });

})(jQuery); // End of use strict

/* Create an array to hold the different image positions */
var itemPositions = [];
var numberOfItems = $('#scroller .item').length;

/* Assign each array element a CSS class based on its initial position */
function assignPositions() {
  for (var i = 0; i < numberOfItems; i++) {
    if (i === 0) {
      itemPositions[i] = 'left-hidden';
    } else if (i === 1) {
      itemPositions[i] = 'left';
    } else if (i === 2) {
      itemPositions[i] = 'middle';
    } else if (i === 3) {
      itemPositions[i] = 'right';
    } else {
      itemPositions[i] = 'right-hidden';
    }
  }
  /* Add each class to the corresponding element */
  $('#scroller .item').each(function(index) {
    $(this).addClass(itemPositions[index]);
  });
}

/* To scroll, we shift the array values by one place and reapply the classes to the images */
function scroll(direction) {
  if (direction === 'prev') {
    itemPositions.push(itemPositions.shift());
  } else if (direction === 'next') {
    itemPositions.unshift(itemPositions.pop());
  }
  $('#scroller .item').removeClass('left-hidden left middle right right-hidden').each(function(index) {
    $(this).addClass(itemPositions[index]);
  });
}

/* Do all this when the DOMs ready */
$(document).ready(function() {

  assignPositions();
  var autoScroll = window.setInterval("scroll('next')", 4000);

  /* Hover behaviours */
  $('#scroller').hover(function() {
    window.clearInterval(autoScroll);
    $('.nav').stop(true, true).fadeIn(200);
  }, function() {
    autoScroll = window.setInterval("scroll('next')", 4000);
    $('.nav').stop(true, true).fadeOut(200);
  });

  /* Click behaviours */
  $('.prev').click(function() {
    scroll('prev');
  });
  $('.next').click(function() {
    scroll('next');
  });

});
