/* globals FreeDraw L */
import { fire, getJSON, delegate } from '@utils';

import polygonArea from './polygon_area';

const MAPS = new WeakMap();

export function initMap(element, position, editable = false) {
  if (MAPS.has(element)) {
    return MAPS.get(element);
  } else {
    const map = L.map(element, {
      scrollWheelZoom: false
    }).setView([position.lat, position.lon], editable ? 18 : position.zoom);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    if (editable) {
      const freeDraw = new FreeDraw({
        mode: FreeDraw.NONE,
        smoothFactor: 4,
        mergePolygons: false
      });
      map.addLayer(freeDraw);
      map.freeDraw = freeDraw;
    }

    MAPS.set(element, map);
    return map;
  }
}

export function drawPolygons(map, data, { editable, initial }) {
  if (initial) {
    drawUserSelection(map, data, editable);
  }
  clearLayers(map);
  drawCadastre(map, data, editable);
  drawQuartiersPrioritaires(map, data, editable);
  drawParcellesAgricoles(map, data, editable);
  bringToFrontUserSelection(map);
}

export function drawUserSelection(map, { selection }, editable = false) {
  if (selection) {
    const coordinates = toLatLngs(selection);
    let polygon;

    if (editable) {
      coordinates.forEach(polygon => map.freeDraw.create(polygon));
      [polygon] = markFreeDrawLayers(map);
    } else {
      polygon = L.polygon(coordinates, {
        color: 'red',
        zIndex: 3
      });
      polygon.addTo(map);
    }

    if (polygon) {
      map.fitBounds(polygon.getBounds());
    }
  }
}

export function addFreeDrawEvents(map, selector) {
  const input = findInput(selector);
  map.freeDraw.on('markers', ({ latLngs }) => {
    if (latLngs.length === 0) {
      input.value = EMPTY_GEO_JSON;
    } else if (polygonArea(latLngs) < 300000) {
      input.value = JSON.stringify(latLngs);
    } else {
      input.value = ERROR_GEO_JSON;
    }

    markFreeDrawLayers(map);
    fire(input, 'change');
  });
}

function drawCadastre(map, { cadastres }, editable = false) {
  drawLayer(
    map,
    cadastres,
    editable ? CADASTRE_POLYGON_STYLE : noEditStyle(CADASTRE_POLYGON_STYLE)
  );
}

function drawQuartiersPrioritaires(
  map,
  { quartiersPrioritaires },
  editable = false
) {
  drawLayer(
    map,
    quartiersPrioritaires,
    editable ? QP_POLYGON_STYLE : noEditStyle(QP_POLYGON_STYLE)
  );
}

function drawParcellesAgricoles(map, { parcellesAgricoles }, editable = false) {
  drawLayer(
    map,
    parcellesAgricoles,
    editable ? RPG_POLYGON_STYLE : noEditStyle(RPG_POLYGON_STYLE)
  );
}

function geocodeAddress(map, query) {
  getJSON('/address/geocode', { request: query }).then(data => {
    if (data.lat !== null) {
      map.setView(new L.LatLng(data.lat, data.lon), data.zoom);
    }
  });
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

const EMPTY_GEO_JSON = '[]';
const ERROR_GEO_JSON = '';

function toLatLngs({ coordinates }) {
  return coordinates.map(polygon =>
    polygon[0].map(point => ({ lng: point[0], lat: point[1] }))
  );
}

function findInput(selector) {
  return typeof selector === 'string'
    ? document.querySelector(selector)
    : selector;
}

function createLayer(map) {
  const layer = new L.GeoJSON(undefined, {
    interactive: false
  });
  layer.addTo(map);
  return layer;
}

function clearLayers(map) {
  map.eachLayer(layer => {
    if (layer instanceof L.GeoJSON) {
      map.removeLayer(layer);
    }
  });
}

function bringToFrontUserSelection(map) {
  map.eachLayer(layer => {
    if (layer.isFreeDraw) {
      layer.bringToFront();
    }
  });
}

function markFreeDrawLayers(map) {
  return map.freeDraw.all().map(layer => {
    layer.isFreeDraw = true;
    return layer;
  });
}

function drawLayer(map, data, style) {
  if (Array.isArray(data) && data.length > 0) {
    const layer = createLayer(map);

    data.forEach(function(item) {
      layer.addData(item.geometry);
    });

    layer.setStyle(style).addTo(map);
  }
}

function noEditStyle(style) {
  return Object.assign({}, style, {
    opacity: 0.7,
    fillOpacity: 0.5,
    color: style.fillColor
  });
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

delegate('autocomplete:select', '.toolbar [data-address]', event => {
  const map = getCurrentMap(event.target);

  if (map) {
    geocodeAddress(map, event.detail.label);
  }
});
