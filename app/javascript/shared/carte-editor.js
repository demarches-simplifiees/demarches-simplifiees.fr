import L from 'leaflet';
import FreeDraw from 'leaflet-freedraw';
import area from '@turf/area';
import { fire, delegate } from '@utils';
import $ from 'jquery';

import createFeatureCollection from './create-feature-collection';

const MAPS = new WeakMap();

export function drawEditableMap(element, data) {
  const map = initMap(element, data);

  drawCadastre(map, data);
  drawQuartiersPrioritaires(map, data);
  drawParcellesAgricoles(map, data);

  drawUserSelectionEditor(map, data);

  const input = element.parentElement.querySelector('input[data-remote]');
  addFreeDrawEvents(map, input);
}

export function redrawMap(element, data) {
  const map = initMap(element, data);

  clearLayers(map);

  drawCadastre(map, data);
  drawQuartiersPrioritaires(map, data);
  drawParcellesAgricoles(map, data);

  bringToFrontUserSelection(map);
}

function initMap(element, { position }) {
  if (MAPS.has(element)) {
    return MAPS.get(element);
  } else {
    const map = L.map(element, {
      scrollWheelZoom: false
    }).setView([position.lat, position.lon], 18);

    const loadTilesLayer = process.env.RAILS_ENV != 'test';
    if (loadTilesLayer) {
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(map);
    }

    const freeDraw = new FreeDraw({
      mode: FreeDraw.NONE,
      smoothFactor: 4,
      mergePolygons: false
    });
    map.addLayer(freeDraw);
    map.freeDraw = freeDraw;

    MAPS.set(element, map);
    return map;
  }
}

function toLatLngs({ coordinates }) {
  return coordinates.map(polygon =>
    polygon[0].map(point => L.GeoJSON.coordsToLatLng(point))
  );
}

function drawUserSelectionEditor(map, { selection }) {
  if (selection) {
    const geoJSON = L.geoJSON(selection);

    for (let polygon of toLatLngs(selection)) {
      map.freeDraw.create(polygon);
    }

    map.fitBounds(geoJSON.getBounds());
  }
}

export function addFreeDrawEvents(map, selector) {
  const input = findInput(selector);

  map.freeDraw.on('markers', ({ latLngs }) => {
    if (latLngs.length === 0) {
      input.value = EMPTY_GEO_JSON;
    } else {
      const featureCollection = createFeatureCollection(latLngs);

      if (area(featureCollection) < 300000) {
        input.value = JSON.stringify(featureCollection);
      } else {
        input.value = ERROR_GEO_JSON;
      }
    }

    fire(input, 'change');
  });
}

function drawCadastre(map, { cadastres }) {
  drawLayer(map, cadastres, CADASTRE_POLYGON_STYLE);
}

function drawQuartiersPrioritaires(map, { quartiersPrioritaires }) {
  drawLayer(map, quartiersPrioritaires, QP_POLYGON_STYLE);
}

function drawParcellesAgricoles(map, { parcellesAgricoles }) {
  drawLayer(map, parcellesAgricoles, RPG_POLYGON_STYLE);
}

function getCurrentMap(element) {
  if (!element.matches('.carte')) {
    const closestCarteElement = element.closest('.carte');
    const closestToolbarElement = element.closest('.toolbar');

    element = closestCarteElement
      ? closestCarteElement
      : closestToolbarElement.parentElement.querySelector('.carte');
  }

  if (MAPS.has(element)) {
    return MAPS.get(element);
  }
}

const EMPTY_GEO_JSON = '{ "type": "FeatureCollection", "features": [] }';
const ERROR_GEO_JSON = '';

function findInput(selector) {
  return typeof selector === 'string'
    ? document.querySelector(selector)
    : selector;
}

function clearLayers(map) {
  map.eachLayer(layer => {
    if (layer instanceof L.GeoJSON) {
      map.removeLayer(layer);
    }
  });
}

function bringToFrontUserSelection(map) {
  for (let layer of map.freeDraw.all()) {
    layer.bringToFront();
  }
}

function drawLayer(map, data, style) {
  if (Array.isArray(data) && data.length > 0) {
    const layer = new L.GeoJSON(undefined, {
      interactive: false,
      style
    });

    for (let { geometry } of data) {
      layer.addData(geometry);
    }

    layer.addTo(map);
  }
}

const POLYGON_STYLE = {
  weight: 2,
  opacity: 0.3,
  color: 'white',
  dashArray: '3',
  fillOpacity: 0.7
};

const CADASTRE_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#8a6d3b'
});

const QP_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#31708f'
});

const RPG_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#31708f'
});

delegate('click', '.carte.edit', event => {
  const map = getCurrentMap(event.target);

  if (map) {
    const isPath = event.target.matches('.leaflet-container g path');
    if (isPath) {
      setTimeout(() => {
        map.freeDraw.mode(FreeDraw.EDIT | FreeDraw.DELETE);
      }, 50);
    } else {
      map.freeDraw.mode(FreeDraw.NONE);
    }
  }
});

delegate('click', '.toolbar .new-area', event => {
  event.preventDefault();
  const map = getCurrentMap(event.target);

  if (map) {
    map.freeDraw.mode(FreeDraw.CREATE);
  }
});

$(document).on('select2:select', 'select[data-address]', event => {
  const map = getCurrentMap(event.target);
  const { geometry } = event.params.data;

  if (map && geometry && geometry.type === 'Point') {
    const [lon, lat] = geometry.coordinates;
    map.setView(new L.LatLng(lat, lon), 14);
  }
});
