import baseStyle from './base-style';
import cadastre from './cadastre';
import orthoStyle from './ortho-style';
import vectorStyle from './vector-style';

function rasterStyle(source) {
  return {
    id: source,
    source,
    type: 'raster',
    paint: { 'raster-resampling': 'linear' }
  };
}

export function getMapStyle(style, hasCadastres, hasMNHN) {
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
      mapStyle.layers = [rasterStyle('plan-ign')];
      mapStyle.id = 'ign';
      mapStyle.name = 'Carte IGN';
      break;
  }

  if (hasCadastres) {
    mapStyle.layers = mapStyle.layers.concat(cadastre);
    mapStyle.id += '-cadastre';
  }

  if (hasMNHN) {
    mapStyle.layers = mapStyle.layers.concat([
      rasterStyle('protectedareas-gp'),
      rasterStyle('protectedareas-pn'),
      rasterStyle('protectedareas-pnr'),
      rasterStyle('protectedareas-sic'),
      rasterStyle('protectedareas-zps')
    ]);
    mapStyle.id += '-mnhn';
  }

  return mapStyle;
}

export { SwitchMapStyle } from './SwitchMapStyle';
