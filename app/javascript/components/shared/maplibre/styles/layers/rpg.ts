import type { LayerSpecification } from 'maplibre-gl';

export const layers: LayerSpecification[] = [
  {
    id: 'parcelles',
    type: 'line',
    source: 'rpg',
    'source-layer': 'parcelles',
    minzoom: 15.5,
    maxzoom: 24,
    layout: {
      visibility: 'visible',
      'line-cap': 'butt',
      'line-join': 'miter',
      'line-miter-limit': 2
    },
    paint: {
      'line-color': 'rgba(255, 255, 255, 1)',
      'line-opacity': 0.8,
      'line-width': {
        type: 'exponential',
        stops: [
          [16, 1.5],
          [17, 2]
        ]
      },
      'line-offset': 0,
      'line-blur': 0,
      'line-translate': [0, 1],
      'line-dasharray': [1],
      'line-gap-width': 0
    }
  },
  {
    id: 'parcelles-fill',
    type: 'fill',
    source: 'rpg',
    'source-layer': 'parcelles',
    layout: {
      visibility: 'visible'
    },
    paint: {
      'fill-color': 'rgba(129, 123, 0, 1)',
      'fill-opacity': [
        'case',
        ['boolean', ['feature-state', 'hover'], false],
        0.7,
        0.1
      ]
    }
  },
  {
    id: 'parcelle-highlighted',
    type: 'fill',
    source: 'rpg',
    'source-layer': 'parcelles',
    filter: ['in', 'id', ''],
    paint: {
      'fill-color': 'rgba(1, 129, 0, 1)',
      'fill-opacity': 0.7
    }
  }
];
