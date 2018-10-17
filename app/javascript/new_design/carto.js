import { getData } from '../shared/data';
import {
  initMap,
  drawCadastre,
  drawQuartiersPrioritaires,
  drawUserSelection
} from '../shared/carte';

function initialize() {
  const element = document.getElementById('map');

  if (element) {
    const data = getData('carto');
    const map = initMap(element, data.position);

    // draw external polygons
    drawCadastre(map, data);
    drawQuartiersPrioritaires(map, data);

    // draw user polygon
    drawUserSelection(map, data);
  }
}

addEventListener('turbolinks:load', initialize);
