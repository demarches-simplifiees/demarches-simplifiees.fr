// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require activestorage
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require highcharts
//= require chartkick
//= require_tree ./old_design
//= require bootstrap-sprockets

//= require leaflet.js
//= require d3.min
//= require clipper
//= require concavehull.min
//= require graham_scan.min
//= require leaflet.freedraw
//= require smart_listing
//= require turf-area
//= require franceconnect
//= require bootstrap-wysihtml5
//= require bootstrap-wysihtml5/locales/fr-FR
//= require handlebars
//= require typeahead.bundle
//= require select2

$(document).on('turbolinks:load', application_init);


function application_init(){
  tooltip_init();
  scroll_to();
}

function tooltip_init() {
  $('.action_button[data-toggle="tooltip"]').tooltip({delay: { "show": 100, "hide": 100 }});
  $('[data-toggle="tooltip"]').tooltip({delay: { "show": 800, "hide": 100 }});
}

function scroll_to() {
  $('.js-scrollTo').on('click', function () { // Au clic sur un élément
    var page = $(this).attr('cible'); // Page cible
    var speed = 600; // Durée de l'animation (en ms)
    $('html, body').animate({scrollTop: $(page).offset().top - 200}, speed); // Go
    return false;
  });
}
