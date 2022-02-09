import type { RasterLayer } from 'maplibre-gl';

const layers: RasterLayer[] = [
  {
    id: 'ign',
    source: 'plan-ign',
    type: 'raster',
    paint: { 'raster-resampling': 'linear' }
  }
];

export default layers;
