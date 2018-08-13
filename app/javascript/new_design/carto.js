import $ from 'jquery';
import L from 'leaflet';

import { getData } from '../shared/data';

import {
  drawCadastre,
  drawQuartiersPrioritaires,
  drawUserSelection
} from './carto/draw';

const LON = '2.428462';
const LAT = '46.538192';
const DEFAULT_POSITION = { lon: LON, lat: LAT, zoom: 5 };

function initialize() {
  if ($('#map').length > 0) {
    $.getJSON(getData('carto').getPositionUrl).then(
      position => initializeWithPosition(position),
      () => initializeWithPosition(DEFAULT_POSITION)
    );
  }
}

addEventListener('turbolinks:load', initialize);

function initializeWithPosition(position) {
  const map = L.map('map', {
    scrollWheelZoom: false
  }).setView([position.lat, position.lon], position.zoom);

  L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution:
      '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);

  const data = getData('carto');

  // draw external polygons
  drawCadastre(map, data);
  drawQuartiersPrioritaires(map, data);

  // draw user polygon
  drawUserSelection(map, data);
}
