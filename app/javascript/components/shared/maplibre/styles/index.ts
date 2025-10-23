import type { LayerSpecification, StyleSpecification } from 'maplibre-gl';

import {
  style as baseStyle,
  buildOptionalLayers,
  getLayerName,
  NBS
} from './base';
import { layers as ignLayers } from './layers/ign.ts';
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

export type MapStyle = 'ortho' | 'vector' | 'ign';

export function getMapStyle(
  id: MapStyle,
  layers: string[],
  opacity: Record<string, number>
): StyleSpecification & { id: MapStyle } {
  const optionalLayers = buildOptionalLayers(layers, opacity);

  switch (id) {
    case 'ortho':
      return {
        ...baseStyle,
        id,
        name: 'Photographies aériennes',
        layers: [...(orthoLayers as LayerSpecification[]), ...optionalLayers]
      };
    case 'vector':
      return {
        ...baseStyle,
        id,
        name: 'Carte OSM',
        layers: [...(vectorLayers as LayerSpecification[]), ...optionalLayers]
      };
    default:
      return {
        ...baseStyle,
        id,
        name: 'Carte IGN',
        layers: [...ignLayers, ...optionalLayers]
      };
  }
}
