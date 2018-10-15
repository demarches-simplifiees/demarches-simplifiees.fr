import L from 'leaflet';

import FreeDraw, { NONE, CREATE } from 'leaflet-freedraw';
import { fire, on, getJSON } from '@utils';

import { getData } from '../shared/data';
import { initMap } from '../shared/carto';

import polygonArea from './carto/polygon_area';
import drawFactory from './carto/draw';

function initialize() {
  if (document.getElementById('map')) {
    const data = getData('carto');
    const position = data.position;

    const map = initMap(position);
    const freeDraw = new FreeDraw({
      mode: NONE,
      smoothFactor: 4,
      mergePolygons: false
    });

    map.addLayer(freeDraw);

    addEventFreeDraw(freeDraw);
    addEventSearchAddress(map);

    const cartoDrawZones = drawFactory(map, freeDraw);
    window.DS = { cartoDrawZones };

    cartoDrawZones(data);

    if (freeDraw.polygons[0]) {
      map.setZoom(18);
      map.fitBounds(freeDraw.polygons[0].getBounds());
    }
  }
}

addEventListener('turbolinks:load', initialize);

function addEventFreeDraw(freeDraw) {
  freeDraw.on('markers', ({ latLngs }) => {
    const input = document.querySelector('input[name=selection]');

    if (polygonArea(latLngs) < 300000) {
      input.value = JSON.stringify(latLngs);
    } else {
      input.value = '{ "error": "TooManyPolygons" }';
    }

    fire(input, 'change');
  });

  on('#map', 'click', () => {
    freeDraw.mode(NONE);
  });

  on('#new', 'click', () => {
    freeDraw.mode(CREATE);
  });
}

function getAddressPoint(map, request) {
  getJSON('/address/address_point', { request }).then(data => {
    if (data.lat !== null) {
      map.setView(new L.LatLng(data.lat, data.lon), data.zoom);
    }
  });
}

function addEventSearchAddress(map) {
  on(
    '#search-by-address input[type=address]',
    'autocomplete:select',
    (_, seggestion) => {
      getAddressPoint(map, seggestion['label']);
    }
  );
}
