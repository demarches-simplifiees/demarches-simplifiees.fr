import baseStyle, { rasterLayer, buildLayers } from './base';
import orthoStyle from './ortho-style';
import vectorStyle from './vector-style';

export function getMapStyle(style, optionalLayers) {
  const mapStyle = { ...baseStyle };

  switch (style) {
    case 'ortho':
      mapStyle.layers = orthoStyle;
      mapStyle.id = 'ortho';
      mapStyle.name = 'Photographies aériennes';
      break;
    case 'vector':
      mapStyle.layers = vectorStyle;
      mapStyle.id = 'vector';
      mapStyle.name = 'Carte OSM';
      break;
    case 'ign':
      mapStyle.layers = [rasterLayer('plan-ign')];
      mapStyle.id = 'ign';
      mapStyle.name = 'Carte IGN';
      break;
  }

  mapStyle.layers = mapStyle.layers.concat(buildLayers(optionalLayers));

  return mapStyle;
}
