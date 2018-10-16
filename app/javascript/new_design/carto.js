import { getData } from '../shared/data';
import { initMap } from '../shared/carto';
import {
  drawCadastre,
  drawQuartiersPrioritaires,
  drawUserSelection
} from './carto/draw';

function initialize() {
  if (document.getElementById('map')) {
    const position = getData('carto').position;
    const map = initMap(position);
    const data = getData('carto');

    // draw external polygons
    drawCadastre(map, data);
    drawQuartiersPrioritaires(map, data);

    // draw user polygon
    drawUserSelection(map, data);
  }
}

addEventListener('turbolinks:load', initialize);
