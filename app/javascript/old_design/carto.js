import { CREATE } from 'leaflet-freedraw';
import { on } from '@utils';
import { getData } from '../shared/data';
import {
  initMap,
  geocodeAddress,
  drawUserSelection,
  drawCadastre,
  drawQuartiersPrioritaires,
  addFreeDrawEvents
} from '../shared/carto';

function initialize() {
  const element = document.getElementById('map');

  if (element) {
    const data = getData('carto');
    const map = initMap(element, data.position, true);

    addAddressSelectEvent(map);

    on('#new', 'click', () => {
      map.freeDraw.mode(CREATE);
    });

    const cartoDrawZones = data => {
      drawCadastre(map, data, true);
      drawQuartiersPrioritaires(map, data, true);
    };

    window.DS = { cartoDrawZones };

    // draw external polygons
    cartoDrawZones(data);

    // draw user polygon
    drawUserSelection(map, data, true);
    addFreeDrawEvents(map, 'input[name=selection]');
  }
}

addEventListener('turbolinks:load', initialize);

function addAddressSelectEvent(map) {
  on(
    '#search-by-address input[type=address]',
    'autocomplete:select',
    (_, { label }) => {
      geocodeAddress(map, label);
    }
  );
}
