import baseStyle from './base-style';
import cadastre from './cadastre';
import orthoStyle from './ortho-style';
import vectorStyle from './vector-style';

const ignStyle = [
  {
    id: 'carte-ign',
    type: 'raster',
    source: 'carte-ign',
    paint: { 'raster-resampling': 'linear' }
  }
];

export function getMapStyle(style, hasCadastres) {
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
      mapStyle.layers = ignStyle;
      mapStyle.id = 'ign';
      mapStyle.name = 'Carte IGN';
      break;
  }

  if (hasCadastres) {
    mapStyle.layers = mapStyle.layers.concat(cadastre);
    mapStyle.id += '-cadastre';
  }

  return mapStyle;
}

export { SwitchMapStyle } from './SwitchMapStyle';
