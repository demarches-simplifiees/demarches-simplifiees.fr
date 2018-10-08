import L from 'leaflet';
import area from '@turf/area';
import FreeDraw, { NONE, EDIT, CREATE, DELETE } from 'leaflet-freedraw';
import $ from 'jquery';

import { getData } from '../shared/data';
import { DEFAULT_POSITION, LAT, LON } from '../shared/carto';
import { qpActive, displayQP, getQP } from './carto/qp';
import { cadastreActive, displayCadastre, getCadastre } from './carto/cadastre';

function initialize() {
  if ($('#map').length > 0) {
    getPosition(getData('carto').dossierId).then(
      position => initializeWithPosition(position),
      () => initializeWithPosition(DEFAULT_POSITION)
    );
  }
}

addEventListener('turbolinks:load', initialize);

function initializeWithPosition(position) {
  const OSM = L.tileLayer(
    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    {
      attribution:
        '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }
  );

  const map = L.map('map', {
    center: new L.LatLng(position.lat, position.lon),
    zoom: position.zoom,
    layers: [OSM],
    scrollWheelZoom: false
  });

  if (qpActive()) {
    displayQP(map, getJsonValue('#quartier_prioritaires'));
  }

  if (cadastreActive()) {
    displayCadastre(map, getJsonValue('#cadastres'));
  }

  const freeDraw = new FreeDraw({
    mode: NONE,
    smoothFactor: 4,
    mergePolygons: false
  });

  map.addLayer(freeDraw);

  const latLngs = getJsonValue('#json_latlngs');

  if (latLngs.length) {
    map.setZoom(18);

    for (let polygon of latLngs) {
      freeDraw.createPolygon(polygon);
    }

    map.fitBounds(freeDraw.polygons[0].getBounds());
  } else if (position.lat == LAT && position.lon == LON) {
    map.setView(new L.LatLng(position.lat, position.lon), position.zoom);
  }

  addEventFreeDraw(map, freeDraw);
  addEventSearchAddress(map);
}

function getExternalData(map, latLngs) {
  const { dossierId } = getData('carto');

  if (qpActive()) {
    getQP(dossierId, latLngs).then(qps => displayQP(map, qps));
  }

  if (cadastreActive()) {
    const polygons = { type: 'FeatureCollection', features: [] };

    for (let i = 0; i < latLngs.length; i++) {
      polygons.features.push(featurePolygonLatLngs(latLngs[i]));
    }

    if (area(polygons) < 300000) {
      getCadastre(dossierId, latLngs).then(cadastres =>
        displayCadastre(map, cadastres)
      );
    } else {
      displayCadastre(map, [{ zoom_error: true }]);
    }
  }
}

function featurePolygonLatLngs(coordinates) {
  return {
    type: 'Feature',
    properties: {},
    geometry: {
      type: 'Polygon',
      coordinates: [JSON.parse(getJsonPolygons([coordinates]))['latLngs']]
    }
  };
}

function addEventFreeDraw(map, freeDraw) {
  freeDraw.on('markers', ({ latLngs }) => {
    $('#json_latlngs').val(JSON.stringify(latLngs));

    addEventEdit(freeDraw);

    getExternalData(map, latLngs);
  });

  $('#map').on('click', () => {
    freeDraw.mode(NONE);
  });

  $('#new').on('click', () => {
    freeDraw.mode(CREATE);
  });
}

function addEventEdit(freeDraw) {
  $('.leaflet-container svg').removeAttr('pointer-events');
  $('.leaflet-container g path').on('click', () => {
    setTimeout(function() {
      freeDraw.mode(EDIT | DELETE);
    }, 50);
  });
}

function getPosition(dossierId) {
  return $.getJSON(`/users/dossiers/${dossierId}/carte/position`);
}

function getAddressPoint(map, request) {
  $.get('/ban/address_point', { request }).then(data => {
    if (data.lat !== null) {
      map.setView(new L.LatLng(data.lat, data.lon), data.zoom);
    }
  });
}

function addEventSearchAddress(map) {
  $("#search-by-address input[type='address']").on(
    'autocomplete:select',
    (_, seggestion) => {
      getAddressPoint(map, seggestion['label']);
    }
  );
}

function getJsonValue(selector) {
  let data = document.querySelector(selector).value;
  if (data && data !== '[]') {
    return JSON.parse(data);
  }
  return [];
}

function getJsonPolygons(latLngGroups) {
  var groups = [];

  latLngGroups.forEach(function forEach(latLngs) {
    var group = [];

    latLngs.forEach(function forEach(latLng) {
      group.push('[' + latLng.lng + ', ' + latLng.lat + ']');
    });

    groups.push('{ "latLngs": [' + group.join(', ') + '] }');
  });

  return groups;
}
