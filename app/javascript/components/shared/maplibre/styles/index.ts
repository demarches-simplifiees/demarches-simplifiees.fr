import type { Style } from 'maplibre-gl';

import baseStyle, { buildOptionalLayers, getLayerName, NBS } from './base';
import orthoStyle from './layers/ortho';
import vectorStyle from './layers/vector';
import ignLayers from './layers/ign';

export { getLayerName, NBS };

export type LayersMap = Record<
  string,
  {
    configurable: boolean;
    enabled: boolean;
    opacity: number;
    name: string;
  }
>;

export function getMapStyle(
  id: string,
  layers: string[],
  opacity: Record<string, number>
): Style & { id: string } {
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

  style.layers = style.layers?.concat(buildOptionalLayers(layers, opacity));

  return style;
}
