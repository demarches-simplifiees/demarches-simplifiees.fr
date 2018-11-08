// Include runtime-polyfills for older browsers.
// Due to .babelrc's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import '@babel/polyfill';

// This file is copied from mailjet. We serve here a copy of it ourselves
// to avoid loading javascript files from other domains on the frontpage.

// Array of popin translations
const i8nMessages = [];
i8nMessages['en_US'] = [];
i8nMessages['fr_FR'] = [];
i8nMessages['de_DE'] = [];
i8nMessages['es_ES'] = [];
i8nMessages['en_US']['iframe-error'] =
  'Your browser does not support the IFrame element';
i8nMessages['en_US']['close-popin'] = 'Close';
i8nMessages['fr_FR']['iframe-error'] =
  "Votre navigateur ne supporte pas l'élément iframe";
i8nMessages['fr_FR']['close-popin'] = 'Fermer';
i8nMessages['de_DE']['iframe-error'] =
  'Ihr navigator verträgt kein Element iframe';
i8nMessages['de_DE']['close-popin'] = 'Schließen';
i8nMessages['es_ES']['iframe-error'] =
  'Su navegante no soporta el elemento iframe';
i8nMessages['es_ES']['close-popin'] = 'Cerrarse';

function mjOpenPopin(event, element) {
  event.preventDefault();
  //event.stopPropagation();

  //var token = str.substring(btnNode.id.lastIndexOf("-") + 1, btnNode.id.length - btnNode.id.lastIndexOf("-"));
  var token = element.getAttribute('data-token');

  //Register parameters
  var widgetPopinData = document.querySelector(
    ".mj-w-data[data-token='" + token + "']"
  );
  if (widgetPopinData) {
    var apiKey = widgetPopinData.getAttribute('data-apikey');
    var wId = widgetPopinData.getAttribute('data-w-id');
    var locale = widgetPopinData.getAttribute('data-lang');
    var base = widgetPopinData.getAttribute('data-base');
    var width = widgetPopinData.getAttribute('data-width');
    var height = widgetPopinData.getAttribute('data-height');
    var statics = widgetPopinData.getAttribute('data-statics');

    // Call to Mailjet CSS file
    var cssFile = document.createElement('link');
    cssFile.setAttribute('rel', 'stylesheet');
    cssFile.setAttribute('type', 'text/css');
    if (statics) {
      base += '/' + statics;
    }
    cssFile.setAttribute('href', base + '/css/w-popin-less.css');
    document.getElementsByTagName('head')[0].appendChild(cssFile);

    var htmlCode =
      '<div id="mj-w-overlay" style="display: none;">' +
      '<div id="mj-w-popin-block" style="max-width:' +
      width +
      'px; max-height:' +
      height +
      'px">' +
      '<div id="mj-w-loader"></div>' +
      '<img id="mj-w-close-img" alt="' +
      i8nMessages[locale]['close-popin'] +
      '" title="' +
      i8nMessages[locale]['close-popin'] +
      '" src="' +
      base +
      '/images/w-popin-close.png" style="display:none;" />' +
      '<iframe id="mj-w-iframe" src="' +
      base +
      '/widget/iframe/' +
      apiKey +
      '/' +
      wId +
      '" scrolling="no" width="100% "   frameborder="0" allotransparency="true" style="background-color:transparent; border-radius:3px;height: 0px;">' +
      '<p>' +
      i8nMessages[locale]['iframe-error'] +
      '</p>' +
      '</iframe>' +
      '</div>' +
      '</div>';

    widgetPopinData.innerHTML = htmlCode;

    document.getElementById('mj-w-iframe').onload = function() {
      document.getElementById('mj-w-iframe').style.height = height + 'px';
      document.getElementById('mj-w-close-img').style.display = 'block';
      document.getElementById('mj-w-loader').style.display = 'none';
      document.getElementById('mj-w-popin-block').style.border = 'none';
      if (window.matchMedia('(max-width: 767px)').matches) {
        document.getElementById('mj-w-iframe').style.width = '100%';
        document.getElementById('mj-w-popin-block').style.height = 'auto';
        document.getElementById('mj-w-popin-block').style.width = '90%';
      }
    };

    var closeImgNode = document.getElementById('mj-w-close-img');
    closeImgNode.addEventListener('click', function(event) {
      closePopin();
      event.preventDefault();
    });

    document.addEventListener('keydown', escapeEvent);
    document.getElementById('mj-w-iframe').onclick = function(event) {
      event.stopPropagation();
    };
    //document.addEventListener("click");

    document.getElementById('mj-w-overlay').style.display = 'block';
    document
      .getElementById('mj-w-overlay')
      .addEventListener('click', function(event) {
        closePopin();
        event.preventDefault();
      });
  }
}

// Escape event : close popin
function escapeEvent(e) {
  if (e.keyCode == 27) {
    // Escape key
    closePopin();
  }
}

// Close popin (remove popin HTML code)
function closePopin() {
  var rootContainer = document.getElementById('mj-w-overlay');
  if (rootContainer) {
    rootContainer.parentNode.removeChild(rootContainer);
  }
  document.removeEventListener('keypress', escapeEvent);
}

addEventListener('load', () => {
  // Display popin when click event occure on widget button
  for (let btnNode of document.getElementsByClassName('mj-w-btn')) {
    btnNode.style.cursor = 'pointer';
    btnNode.addEventListener('click', function(event) {
      mjOpenPopin(event, this);
    });
  }
});

addEventListener('resize', () => {
  if (window.matchMedia('(max-width: 767px)').matches) {
    const popin = document.getElementById('mj-w-popin-block');
    const iframe = document.getElementById('mj-w-iframe');
    if (popin) {
      popin.style.height = 'auto';
      popin.style.width = '90%';
    }
    if (iframe) {
      iframe.style.width = '100%';
    }
  }
});

window.mjOpenPopin = mjOpenPopin;
