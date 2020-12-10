export default [
  {
    id: 'batiments-line',
    type: 'line',
    source: 'cadastre',
    'source-layer': 'batiments',
    minzoom: 16,
    maxzoom: 22,
    layout: { visibility: 'visible' },
    paint: {
      'line-opacity': 1,
      'line-color': 'rgba(0, 0, 0, 1)',
      'line-width': 1
    }
  },
  {
    id: 'batiments-fill',
    type: 'fill',
    source: 'cadastre',
    'source-layer': 'batiments',
    layout: { visibility: 'visible' },
    paint: {
      'fill-color': 'rgba(150, 150, 150, 1)',
      'fill-opacity': {
        stops: [
          [16, 0],
          [17, 0.6]
        ]
      },
      'fill-antialias': true
    }
  },
  {
    id: 'parcelles',
    type: 'line',
    source: 'cadastre',
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
    source: 'cadastre',
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
    source: 'cadastre',
    'source-layer': 'parcelles',
    filter: ['==', 'id', ''],
    paint: {
      'fill-color': 'rgba(1, 129, 0, 1)',
      'fill-opacity': 0.7
    }
  },
  {
    id: 'sections',
    type: 'line',
    source: 'cadastre',
    'source-layer': 'sections',
    minzoom: 12,
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'rgba(0, 0, 0, 1)',
      'line-opacity': 0.7,
      'line-width': 2,
      'line-dasharray': [3, 3],
      'line-translate': [0, 0]
    }
  }
];
