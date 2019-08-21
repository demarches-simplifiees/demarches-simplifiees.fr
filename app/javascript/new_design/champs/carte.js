import { initMap, drawPolygons, addFreeDrawEvents } from '../../shared/carte';

async function initialize() {
  const elements = document.querySelectorAll('.carte');

  if (elements.length) {
    const editable = [...elements].find(element =>
      element.classList.contains('edit')
    );
    await loadLeaflet(editable);

    for (let element of elements) {
      diplayMap(element, null, true);
    }
  }
}

// We load leaflet dynamically, ramda and freedraw and assign them to globals.
// Latest freedraw version build needs globals.
async function loadLeaflet(editable) {
  window.L = await import('leaflet').then(({ default: L }) => L);

  if (editable) {
    window.R = await import('ramda').then(({ default: R }) => R);
    await import('leaflet-freedraw/dist/leaflet-freedraw.web.js');
  }
}

function diplayMap(element, data, initial = false) {
  data = data || JSON.parse(element.dataset.geo);
  const editable = element.classList.contains('edit');
  const map = initMap(element, data.position, editable);

  drawPolygons(map, data, { initial, editable });

  if (initial && editable) {
    const input = element.parentElement.querySelector('input[data-remote]');
    addFreeDrawEvents(map, input);
  }
}

addEventListener('turbolinks:load', initialize);

addEventListener('carte:update', ({ detail: { selector, data } }) => {
  const element = document.querySelector(selector);
  diplayMap(element, data);
});
