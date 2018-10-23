import { CREATE } from 'leaflet-freedraw';
import { delegate } from '@utils';
import {
  initMap,
  getCurrentMap,
  geocodeAddress,
  drawCadastre,
  drawQuartiersPrioritaires,
  drawParcellesAgricoles,
  drawUserSelection,
  addFreeDrawEvents
} from '../../shared/carte';

function initialize() {
  for (let element of document.querySelectorAll('.carte')) {
    diplayMap(element, null, true);
  }

  window.DS.drawMapData = (selector, data) => {
    let element = document.querySelector(selector);
    diplayMap(element, data);
  };
}

function diplayMap(element, data, initial = false) {
  data = data || JSON.parse(element.dataset.geo);
  let editable = element.classList.contains('edit');

  let map = initMap(element, data.position, editable);

  // draw external polygons
  drawCadastre(map, data, editable);
  drawQuartiersPrioritaires(map, data, editable);
  drawParcellesAgricoles(map, data, editable);

  // draw user polygon
  if (initial) {
    drawUserSelection(map, data, editable);

    if (editable) {
      let input = element.parentElement.querySelector('input[data-remote]');
      addFreeDrawEvents(map, input);
    }
  }
}

addEventListener('turbolinks:load', initialize);

delegate('click', '.toolbar .new-area', event => {
  event.preventDefault();
  let map = getCurrentMap(event.target);

  if (map) {
    map.freeDraw.mode(CREATE);
  }
});

delegate('autocomplete:select', '.toolbar [data-address]', event => {
  let map = getCurrentMap(event.target);

  if (map) {
    geocodeAddress(map, event.detail.label);
  }
});
