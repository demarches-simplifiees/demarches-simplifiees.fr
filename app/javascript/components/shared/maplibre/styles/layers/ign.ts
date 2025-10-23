import type { LayerSpecification } from 'maplibre-gl';

export const layers: LayerSpecification[] = [
  {
    id: 'ign',
    source: 'plan-ign',
    type: 'raster',
    paint: { 'raster-resampling': 'linear' }
  }
];
