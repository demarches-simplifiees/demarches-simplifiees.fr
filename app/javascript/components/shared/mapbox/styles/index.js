import baseStyle, { buildOptionalLayers, getLayerName, NBS } from './base';
import orthoStyle from './layers/ortho';
import vectorStyle from './layers/vector';
import ignLayers from './layers/ign';

export { getLayerName, NBS };

export function getMapStyle(id, layers, opacity) {
  const style = { ...baseStyle, id };

  switch (id) {
    case 'ortho':
      style.layers = orthoStyle;
      style.name = 'Photographies aériennes';
      break;
    case 'vector':
      style.layers = vectorStyle;
      style.name = 'Carte OSM';
      break;
    case 'ign':
      style.layers = ignLayers;
      style.name = 'Carte IGN';
      break;
  }

  style.layers = style.layers.concat(buildOptionalLayers(layers, opacity));

  return style;
}
