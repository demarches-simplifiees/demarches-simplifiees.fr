import { EDIT, DELETE } from 'leaflet-freedraw';
import { on } from '@utils';

import {
  drawLayer,
  CADASTRE_POLYGON_STYLE,
  QP_POLYGON_STYLE
} from '../../shared/carto';

const SOURCES = {
  cadastres: CADASTRE_POLYGON_STYLE,
  quartiersPrioritaires: QP_POLYGON_STYLE
};

export default function draw(map, freeDraw) {
  return data => {
    if (data.selection) {
      drawSelection(freeDraw, data.selection);
    }
    for (let source of Object.keys(SOURCES)) {
      if (data[source]) {
        drawLayer(map, data[source], SOURCES[source], source);
      }
    }
    addEventEdit(freeDraw);
  };
}

function drawSelection(selection, freeDraw) {
  for (let polygon of selection) {
    freeDraw.createPolygon(polygon);
  }
}

function addEventEdit(freeDraw) {
  document
    .querySelector('.leaflet-container svg')
    .removeAttribute('pointer-events');

  on('.leaflet-container g path', 'click', () => {
    setTimeout(() => {
      freeDraw.mode(EDIT | DELETE);
    }, 50);
  });
}
