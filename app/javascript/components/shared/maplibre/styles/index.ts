import type { LayerSpecification, StyleSpecification } from 'maplibre-gl';

import {
  style as baseStyle,
  buildOptionalLayers,
  getLayerName,
  NBS
} from './base';
import ignLayers from './layers/ign.json';
import orthoLayers from './layers/ortho.json';
import vectorLayers from './layers/vector.json';

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
): StyleSpecification & { id: string } {
  const style = { ...baseStyle, id };

  switch (id) {
    case 'ortho':
      style.layers = orthoLayers as LayerSpecification[];
      style.name = 'Photographies aériennes';
      break;
    case 'vector':
      style.layers = vectorLayers as LayerSpecification[];
      style.name = 'Carte OSM';
      break;
    case 'ign':
      style.layers = ignLayers as LayerSpecification[];
      style.name = 'Carte IGN';
      break;
  }

  style.layers = style.layers?.concat(buildOptionalLayers(layers, opacity));

  return style;
}
