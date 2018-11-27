import L from 'leaflet';
import FreeDraw, { NONE, EDIT, DELETE } from 'leaflet-freedraw';
import { fire, getJSON, delegate } from '@utils';

import polygonArea from './polygon_area';

const LAYERS = {};
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
        mode: NONE,
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

export function drawCadastre(map, { cadastres }, editable = false) {
  drawLayer(
    map,
    cadastres,
    editable ? CADASTRE_POLYGON_STYLE : noEditStyle(CADASTRE_POLYGON_STYLE),
    'cadastres'
  );
}

export function drawQuartiersPrioritaires(
  map,
  { quartiersPrioritaires },
  editable = false
) {
  drawLayer(
    map,
    quartiersPrioritaires,
    editable ? QP_POLYGON_STYLE : noEditStyle(QP_POLYGON_STYLE),
    'quartiersPrioritaires'
  );
}

export function drawParcellesAgricoles(
  map,
  { parcellesAgricoles },
  editable = false
) {
  drawLayer(
    map,
    parcellesAgricoles,
    editable ? RPG_POLYGON_STYLE : noEditStyle(RPG_POLYGON_STYLE),
    'parcellesAgricoles'
  );
}

export function drawUserSelection(map, { selection }, editable = false) {
  let hasSelection = selection && selection.length > 0;

  if (editable) {
    if (hasSelection) {
      selection.forEach(polygon => map.freeDraw.create(polygon));
      let polygon = map.freeDraw.all()[0];
      if (polygon) {
        map.fitBounds(polygon.getBounds());
      }
    }
  } else if (hasSelection) {
    const polygon = L.polygon(selection, {
      color: 'red',
      zIndex: 3
    }).addTo(map);

    map.fitBounds(polygon.getBounds());
  }
}

export function geocodeAddress(map, query) {
  getJSON('/address/geocode', { request: query }).then(data => {
    if (data.lat !== null) {
      map.setView(new L.LatLng(data.lat, data.lon), data.zoom);
    }
  });
}

export function getCurrentMap(input) {
  let element = input.closest('.toolbar').parentElement.querySelector('.carte');

  if (MAPS.has(element)) {
    return MAPS.get(element);
  }
}

const EMPTY_GEO_JSON = '[]';
const ERROR_GEO_JSON = '';

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

    fire(input, 'change');
  });
}

function findInput(selector) {
  return typeof selector === 'string'
    ? document.querySelector(selector)
    : selector;
}

function createLayer(map, layerName) {
  const layer = (LAYERS[layerName] = new L.GeoJSON(undefined, {
    interactive: false
  }));
  layer.addTo(map);
  return layer;
}

function removeLayer(map, layerName) {
  const layer = LAYERS[layerName];

  if (layer) {
    delete LAYERS[layerName];
    map.removeLayer(layer);
  }
}

function drawLayer(map, data, style, layerName = 'default') {
  removeLayer(map, layerName);

  if (Array.isArray(data) && data.length > 0) {
    const layer = createLayer(map, layerName);

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
  let element = event.target;
  let isPath = element.matches('.leaflet-container g path');
  let map = element.matches('.carte') ? element : element.closest('.carte');
  let freeDraw = MAPS.has(map) ? MAPS.get(map).freeDraw : null;

  if (freeDraw) {
    if (isPath) {
      setTimeout(() => {
        freeDraw.mode(EDIT | DELETE);
      }, 50);
    } else {
      freeDraw.mode(NONE);
    }
  }
});
