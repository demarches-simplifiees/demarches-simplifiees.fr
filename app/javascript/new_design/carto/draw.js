import L from 'leaflet';
import {
  drawLayer,
  noEditStyle,
  CADASTRE_POLYGON_STYLE,
  QP_POLYGON_STYLE
} from '../../shared/carto';

export function drawCadastre(map, data) {
  drawLayer(
    map,
    data.cadastres,
    noEditStyle(CADASTRE_POLYGON_STYLE),
    'cadastres'
  );
}

export function drawQuartiersPrioritaires(map, data) {
  drawLayer(
    map,
    data.quartiersPrioritaires,
    noEditStyle(QP_POLYGON_STYLE),
    'quartiersPrioritaires'
  );
}

export function drawUserSelection(map, data) {
  if (data.selection.length > 0) {
    const polygon = L.polygon(data.selection, {
      color: 'red',
      zIndex: 3
    }).addTo(map);
    map.fitBounds(polygon.getBounds());
  }
}
