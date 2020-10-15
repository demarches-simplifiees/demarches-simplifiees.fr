export default [
  {
    id: 'photographies-aeriennes',
    type: 'raster',
    source: 'photographies-aeriennes',
    paint: { 'raster-resampling': 'linear' }
  },
  {
    id: 'communes',
    type: 'line',
    source: 'decoupage-administratif',
    'source-layer': 'communes',
    minzoom: 10,
    maxzoom: 24,
    filter: ['all'],
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'rgba(0, 0, 0, 1)',
      'line-width': 1.5,
      'line-opacity': 1,
      'line-blur': 0
    }
  },
  {
    id: 'departements',
    type: 'line',
    source: 'decoupage-administratif',
    'source-layer': 'departements',
    minzoom: 0,
    maxzoom: 24,
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'rgba(0, 0, 0, 1)',
      'line-width': 1,
      'line-opacity': 1
    }
  },
  {
    id: 'regions',
    type: 'line',
    source: 'decoupage-administratif',
    'source-layer': 'regions',
    minzoom: 0,
    maxzoom: 24,
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'rgba(0, 0, 0, 1)',
      'line-width': 1,
      'line-opacity': 1
    }
  },
  {
    id: 'waterway_tunnel',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'waterway',
    minzoom: 14,
    filter: [
      'all',
      ['in', 'class', 'river', 'stream', 'canal'],
      ['==', 'brunnel', 'tunnel']
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-dasharray': [2, 4],
      'line-width': {
        base: 1.3,
        stops: [
          [13, 0.5],
          [20, 6]
        ]
      }
    }
  },
  {
    id: 'waterway-other',
    type: 'line',
    metadata: { 'mapbox:group': '1444849382550.77' },
    source: 'openmaptiles',
    'source-layer': 'waterway',
    filter: [
      'all',
      ['!in', 'class', 'canal', 'river', 'stream'],
      ['==', 'intermittent', 0]
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-width': {
        base: 1.3,
        stops: [
          [13, 0.5],
          [20, 2]
        ]
      }
    }
  },
  {
    id: 'waterway-other-intermittent',
    type: 'line',
    metadata: { 'mapbox:group': '1444849382550.77' },
    source: 'openmaptiles',
    'source-layer': 'waterway',
    filter: [
      'all',
      ['!in', 'class', 'canal', 'river', 'stream'],
      ['==', 'intermittent', 1]
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-width': {
        base: 1.3,
        stops: [
          [13, 0.5],
          [20, 2]
        ]
      },
      'line-dasharray': [4, 3]
    }
  },
  {
    id: 'waterway-stream-canal',
    type: 'line',
    metadata: { 'mapbox:group': '1444849382550.77' },
    source: 'openmaptiles',
    'source-layer': 'waterway',
    filter: [
      'all',
      ['in', 'class', 'canal', 'stream'],
      ['!=', 'brunnel', 'tunnel'],
      ['==', 'intermittent', 0]
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-width': {
        base: 1.3,
        stops: [
          [13, 0.5],
          [20, 6]
        ]
      }
    }
  },
  {
    id: 'waterway-stream-canal-intermittent',
    type: 'line',
    metadata: { 'mapbox:group': '1444849382550.77' },
    source: 'openmaptiles',
    'source-layer': 'waterway',
    filter: [
      'all',
      ['in', 'class', 'canal', 'stream'],
      ['!=', 'brunnel', 'tunnel'],
      ['==', 'intermittent', 1]
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-width': {
        base: 1.3,
        stops: [
          [13, 0.5],
          [20, 6]
        ]
      },
      'line-dasharray': [4, 3]
    }
  },
  {
    id: 'waterway-river',
    type: 'line',
    metadata: { 'mapbox:group': '1444849382550.77' },
    source: 'openmaptiles',
    'source-layer': 'waterway',
    filter: [
      'all',
      ['==', 'class', 'river'],
      ['!=', 'brunnel', 'tunnel'],
      ['==', 'intermittent', 0]
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-width': {
        base: 1.2,
        stops: [
          [10, 0.8],
          [20, 6]
        ]
      }
    }
  },
  {
    id: 'waterway-river-intermittent',
    type: 'line',
    metadata: { 'mapbox:group': '1444849382550.77' },
    source: 'openmaptiles',
    'source-layer': 'waterway',
    filter: [
      'all',
      ['==', 'class', 'river'],
      ['!=', 'brunnel', 'tunnel'],
      ['==', 'intermittent', 1]
    ],
    layout: { 'line-cap': 'round', visibility: 'none' },
    paint: {
      'line-color': '#a0c8f0',
      'line-width': {
        base: 1.2,
        stops: [
          [10, 0.8],
          [20, 6]
        ]
      },
      'line-dasharray': [3, 2.5]
    }
  },
  {
    id: 'tunnel-service-track-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'tunnel'],
      ['in', 'class', 'service', 'track']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#cfcdca',
      'line-dasharray': [0.5, 0.25],
      'line-width': {
        base: 1.2,
        stops: [
          [15, 1],
          [16, 4],
          [20, 11]
        ]
      }
    }
  },
  {
    id: 'tunnel-minor-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'tunnel'], ['==', 'class', 'minor']],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#cfcdca',
      'line-opacity': {
        stops: [
          [12, 0],
          [12.5, 1]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [12, 0.5],
          [13, 1],
          [14, 4],
          [20, 15]
        ]
      }
    }
  },
  {
    id: 'tunnel-secondary-tertiary-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'tunnel'],
      ['in', 'class', 'secondary', 'tertiary']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': 1,
      'line-width': {
        base: 1.2,
        stops: [
          [8, 1.5],
          [20, 17]
        ]
      }
    }
  },
  {
    id: 'tunnel-trunk-primary-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'tunnel'],
      ['in', 'class', 'primary', 'trunk']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-width': {
        base: 1.2,
        stops: [
          [5, 0.4],
          [6, 0.6],
          [7, 1.5],
          [20, 22]
        ]
      }
    }
  },
  {
    id: 'tunnel-motorway-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'tunnel'], ['==', 'class', 'motorway']],
    layout: { 'line-join': 'round', visibility: 'visible' },
    paint: {
      'line-color': '#e9ac77',
      'line-dasharray': [0.5, 0.25],
      'line-width': {
        base: 1.2,
        stops: [
          [5, 0.4],
          [6, 0.6],
          [7, 1.5],
          [20, 22]
        ]
      }
    }
  },
  {
    id: 'tunnel-path',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'brunnel', 'tunnel'], ['==', 'class', 'path']]
    ],
    paint: {
      'line-color': '#cba',
      'line-dasharray': [1.5, 0.75],
      'line-width': {
        base: 1.2,
        stops: [
          [15, 1.2],
          [20, 4]
        ]
      }
    }
  },
  {
    id: 'tunnel-service-track',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'tunnel'],
      ['in', 'class', 'service', 'track']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fff',
      'line-width': {
        base: 1.2,
        stops: [
          [15.5, 0],
          [16, 2],
          [20, 7.5]
        ]
      }
    }
  },
  {
    id: 'tunnel-minor',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'tunnel'], ['==', 'class', 'minor_road']],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fff',
      'line-opacity': 1,
      'line-width': {
        base: 1.2,
        stops: [
          [13.5, 0],
          [14, 2.5],
          [20, 11.5]
        ]
      }
    }
  },
  {
    id: 'tunnel-secondary-tertiary',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'tunnel'],
      ['in', 'class', 'secondary', 'tertiary']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fff4c6',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 10]
        ]
      }
    }
  },
  {
    id: 'tunnel-trunk-primary',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'tunnel'],
      ['in', 'class', 'primary', 'trunk']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fff4c6',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 18]
        ]
      }
    }
  },
  {
    id: 'tunnel-motorway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'tunnel'], ['==', 'class', 'motorway']],
    layout: { 'line-join': 'round', visibility: 'visible' },
    paint: {
      'line-color': '#ffdaa6',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 18]
        ]
      }
    }
  },
  {
    id: 'tunnel-railway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849354174.1904' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'tunnel'], ['==', 'class', 'rail']],
    paint: {
      'line-color': '#bbb',
      'line-dasharray': [2, 2],
      'line-width': {
        base: 1.4,
        stops: [
          [14, 0.4],
          [15, 0.75],
          [20, 2]
        ]
      }
    }
  },
  {
    id: 'ferry',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['in', 'class', 'ferry']],
    layout: { 'line-join': 'round', visibility: 'visible' },
    paint: {
      'line-color': 'rgba(108, 159, 182, 1)',
      'line-dasharray': [2, 2],
      'line-width': 1.1
    }
  },
  {
    id: 'aeroway-taxiway-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'aeroway',
    minzoom: 12,
    filter: ['all', ['in', 'class', 'taxiway']],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': 'rgba(153, 153, 153, 1)',
      'line-opacity': 1,
      'line-width': {
        base: 1.5,
        stops: [
          [11, 2],
          [17, 12]
        ]
      }
    }
  },
  {
    id: 'aeroway-runway-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'aeroway',
    minzoom: 12,
    filter: ['all', ['in', 'class', 'runway']],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': 'rgba(153, 153, 153, 1)',
      'line-opacity': 0.2,
      'line-width': {
        base: 1.5,
        stops: [
          [11, 5],
          [17, 55]
        ]
      }
    }
  },
  {
    id: 'aeroway-taxiway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'aeroway',
    minzoom: 4,
    filter: ['all', ['in', 'class', 'taxiway'], ['==', '$type', 'LineString']],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': 'rgba(255, 255, 255, 1)',
      'line-opacity': {
        base: 1,
        stops: [
          [11, 0],
          [12, 1]
        ]
      },
      'line-width': {
        base: 1.5,
        stops: [
          [11, 1],
          [17, 10]
        ]
      }
    }
  },
  {
    id: 'aeroway-runway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'aeroway',
    minzoom: 4,
    filter: ['all', ['in', 'class', 'runway'], ['==', '$type', 'LineString']],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': 'rgba(255, 255, 255, 1)',
      'line-opacity': {
        base: 1,
        stops: [
          [11, 0],
          [12, 0.2]
        ]
      },
      'line-width': {
        base: 1.5,
        stops: [
          [11, 4],
          [17, 50]
        ]
      }
    }
  },
  {
    id: 'road_area_pier',
    type: 'fill',
    metadata: {},
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', '$type', 'Polygon'], ['==', 'class', 'pier']],
    layout: { visibility: 'visible' },
    paint: { 'fill-antialias': true, 'fill-color': '#f8f4f0' }
  },
  {
    id: 'road_pier',
    type: 'line',
    metadata: {},
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', '$type', 'LineString'], ['in', 'class', 'pier']],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#f8f4f0',
      'line-width': {
        base: 1.2,
        stops: [
          [15, 1],
          [17, 4]
        ]
      }
    }
  },
  {
    id: 'highway-area',
    type: 'fill',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', '$type', 'Polygon'], ['!in', 'class', 'pier']],
    layout: { visibility: 'visible' },
    paint: {
      'fill-antialias': false,
      'fill-color': 'hsla(0, 0%, 89%, 0.56)',
      'fill-opacity': {
        stops: [
          [15, 0],
          [16, 0.9]
        ]
      },
      'fill-outline-color': '#cfcdca'
    }
  },
  {
    id: 'highway-motorway-link-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 12,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['==', 'class', 'motorway_link']
    ],
    layout: { 'line-cap': 'round', 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': 1,
      'line-width': {
        base: 1.2,
        stops: [
          [12, 1],
          [13, 3],
          [14, 4],
          [20, 15]
        ]
      }
    }
  },
  {
    id: 'highway-link-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 13,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      [
        'in',
        'class',
        'primary_link',
        'secondary_link',
        'tertiary_link',
        'trunk_link'
      ]
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': 1,
      'line-width': {
        base: 1.2,
        stops: [
          [12, 1],
          [13, 3],
          [14, 4],
          [20, 15]
        ]
      }
    }
  },
  {
    id: 'highway-minor-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      [
        'all',
        ['!=', 'brunnel', 'tunnel'],
        ['in', 'class', 'minor', 'service', 'track']
      ]
    ],
    layout: { 'line-cap': 'round', 'line-join': 'round' },
    paint: {
      'line-color': '#cfcdca',
      'line-opacity': {
        stops: [
          [14, 0],
          [15, 0.5]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [15, 0.5],
          [16, 5]
        ]
      }
    }
  },
  {
    id: 'highway-secondary-tertiary-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['in', 'class', 'secondary', 'tertiary']
    ],
    layout: {
      'line-cap': 'butt',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': {
        stops: [
          [15, 0],
          [16, 0.3]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [8, 1.5],
          [20, 17]
        ]
      }
    }
  },
  {
    id: 'highway-primary-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 5,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['in', 'class', 'primary']
    ],
    layout: {
      'line-cap': 'butt',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': {
        stops: [
          [16, 0],
          [17, 0.3]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [7, 0],
          [8, 0.6],
          [9, 1.5],
          [20, 22]
        ]
      }
    }
  },
  {
    id: 'highway-trunk-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 5,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['in', 'class', 'trunk']
    ],
    layout: {
      'line-cap': 'butt',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': {
        stops: [
          [16, 0],
          [17, 0.3]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [5, 0],
          [6, 0.6],
          [7, 1.5],
          [20, 22]
        ]
      }
    }
  },
  {
    id: 'highway-motorway-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 4,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['==', 'class', 'motorway']
    ],
    layout: {
      'line-cap': 'butt',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': {
        stops: [
          [8, 0],
          [9, 0.2]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [4, 0],
          [5, 0.4],
          [6, 0.6],
          [7, 1.5],
          [20, 22]
        ]
      }
    }
  },
  {
    id: 'highway-path',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['!in', 'brunnel', 'bridge', 'tunnel'], ['==', 'class', 'path']]
    ],
    layout: { visibility: 'none' },
    paint: {
      'line-color': '#cba',
      'line-dasharray': [1.5, 0.75],
      'line-width': {
        base: 1.2,
        stops: [
          [15, 1.2],
          [20, 4]
        ]
      }
    }
  },
  {
    id: 'highway-motorway-link',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 12,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['==', 'class', 'motorway_link']
    ],
    layout: { 'line-cap': 'round', 'line-join': 'round' },
    paint: {
      'line-color': '#fc8',
      'line-width': {
        base: 1.2,
        stops: [
          [12.5, 0],
          [13, 1.5],
          [14, 2.5],
          [20, 11.5]
        ]
      }
    }
  },
  {
    id: 'highway-link',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 13,
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      [
        'in',
        'class',
        'primary_link',
        'secondary_link',
        'tertiary_link',
        'trunk_link'
      ]
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [12.5, 0],
          [13, 1.5],
          [14, 2.5],
          [20, 11.5]
        ]
      }
    }
  },
  {
    id: 'highway-minor',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      [
        'all',
        ['!=', 'brunnel', 'tunnel'],
        ['in', 'class', 'minor', 'service', 'track']
      ]
    ],
    layout: { 'line-cap': 'round', 'line-join': 'round' },
    paint: {
      'line-color': '#fff',
      'line-opacity': {
        stops: [
          [16, 0],
          [17, 0.4]
        ]
      },
      'line-width': {
        base: 1.2,
        stops: [
          [16, 0],
          [17, 2.5]
        ]
      }
    }
  },
  {
    id: 'highway-secondary-tertiary',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['!in', 'brunnel', 'bridge', 'tunnel'],
      ['in', 'class', 'secondary', 'tertiary']
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [8, 0.5],
          [20, 13]
        ]
      },
      'line-opacity': {
        stops: [
          [11, 0],
          [13, 0.3]
        ]
      }
    }
  },
  {
    id: 'highway-primary',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      [
        'all',
        ['!in', 'brunnel', 'bridge', 'tunnel'],
        ['in', 'class', 'primary']
      ]
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [8.5, 0],
          [9, 0.5],
          [20, 18]
        ]
      },
      'line-opacity': {
        stops: [
          [8, 0],
          [9, 0.3]
        ]
      }
    }
  },
  {
    id: 'highway-trunk',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['!in', 'brunnel', 'bridge', 'tunnel'], ['in', 'class', 'trunk']]
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 18]
        ]
      },
      'line-opacity': {
        stops: [
          [16, 0],
          [17, 0.3]
        ]
      }
    }
  },
  {
    id: 'highway-motorway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 5,
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      [
        'all',
        ['!in', 'brunnel', 'bridge', 'tunnel'],
        ['==', 'class', 'motorway']
      ]
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': '#fc8',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 18]
        ]
      },
      'line-opacity': {
        stops: [
          [8, 0],
          [9, 0.2]
        ]
      }
    }
  },
  {
    id: 'railway-transit',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'class', 'transit'], ['!in', 'brunnel', 'tunnel']]
    ],
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'hsla(0, 0%, 73%, 0.77)',
      'line-width': {
        base: 1.4,
        stops: [
          [14, 0.4],
          [20, 1]
        ]
      }
    }
  },
  {
    id: 'railway-transit-hatching',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'class', 'transit'], ['!in', 'brunnel', 'tunnel']]
    ],
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'hsla(0, 0%, 73%, 0.68)',
      'line-dasharray': [0.2, 8],
      'line-width': {
        base: 1.4,
        stops: [
          [14.5, 0],
          [15, 2],
          [20, 6]
        ]
      }
    }
  },
  {
    id: 'railway-service',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'class', 'rail'], ['has', 'service']]
    ],
    paint: {
      'line-color': 'hsla(0, 0%, 73%, 0.77)',
      'line-width': {
        base: 1.4,
        stops: [
          [14, 0.4],
          [20, 1]
        ]
      }
    }
  },
  {
    id: 'railway-service-hatching',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'class', 'rail'], ['has', 'service']]
    ],
    layout: { visibility: 'visible' },
    paint: {
      'line-color': 'hsla(0, 0%, 73%, 0.68)',
      'line-dasharray': [0.2, 8],
      'line-width': {
        base: 1.4,
        stops: [
          [14.5, 0],
          [15, 2],
          [20, 6]
        ]
      }
    }
  },
  {
    id: 'railway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      [
        'all',
        ['!has', 'service'],
        ['!in', 'brunnel', 'bridge', 'tunnel'],
        ['==', 'class', 'rail']
      ]
    ],
    layout: { visibility: 'visible' },
    paint: {
      'line-color': '#bbb',
      'line-width': {
        base: 1.4,
        stops: [
          [14, 0.4],
          [15, 0.75],
          [20, 2]
        ]
      },
      'line-opacity': {
        stops: [
          [11, 0],
          [13, 1]
        ]
      }
    }
  },
  {
    id: 'railway-hatching',
    type: 'line',
    metadata: { 'mapbox:group': '1444849345966.4436' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      [
        'all',
        ['!has', 'service'],
        ['!in', 'brunnel', 'bridge', 'tunnel'],
        ['==', 'class', 'rail']
      ]
    ],
    paint: {
      'line-color': '#bbb',
      'line-dasharray': [0.2, 8],
      'line-width': {
        base: 1.4,
        stops: [
          [14.5, 0],
          [15, 3],
          [20, 8]
        ]
      }
    }
  },
  {
    id: 'bridge-motorway-link-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      ['==', 'class', 'motorway_link']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': 1,
      'line-width': {
        base: 1.2,
        stops: [
          [12, 1],
          [13, 3],
          [14, 4],
          [20, 15]
        ]
      }
    }
  },
  {
    id: 'bridge-link-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      [
        'in',
        'class',
        'primary_link',
        'secondary_link',
        'tertiary_link',
        'trunk_link'
      ]
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': 1,
      'line-width': {
        base: 1.2,
        stops: [
          [12, 1],
          [13, 3],
          [14, 4],
          [20, 15]
        ]
      }
    }
  },
  {
    id: 'bridge-secondary-tertiary-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      ['in', 'class', 'secondary', 'tertiary']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-opacity': 0.3,
      'line-width': {
        base: 1.2,
        stops: [
          [8, 1.5],
          [20, 28]
        ]
      }
    }
  },
  {
    id: 'bridge-trunk-primary-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      ['in', 'class', 'primary', 'trunk']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': 'hsl(28, 76%, 67%)',
      'line-width': {
        base: 1.2,
        stops: [
          [5, 0.4],
          [6, 0.6],
          [7, 1.5],
          [20, 26]
        ]
      },
      'line-opacity': 0.3
    }
  },
  {
    id: 'bridge-motorway-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'bridge'], ['==', 'class', 'motorway']],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#e9ac77',
      'line-width': {
        base: 1.2,
        stops: [
          [5, 0.4],
          [6, 0.6],
          [7, 1.5],
          [20, 22]
        ]
      },
      'line-opacity': {
        stops: [
          [16, 0],
          [17, 0.3]
        ]
      }
    }
  },
  {
    id: 'bridge-path-casing',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'brunnel', 'bridge'], ['==', 'class', 'path']]
    ],
    paint: {
      'line-color': '#f8f4f0',
      'line-width': {
        base: 1.2,
        stops: [
          [15, 1.2],
          [20, 18]
        ]
      }
    }
  },
  {
    id: 'bridge-path',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['all', ['==', 'brunnel', 'bridge'], ['==', 'class', 'path']]
    ],
    paint: {
      'line-color': '#cba',
      'line-dasharray': [1.5, 0.75],
      'line-width': {
        base: 1.2,
        stops: [
          [15, 1.2],
          [20, 4]
        ]
      }
    }
  },
  {
    id: 'bridge-motorway-link',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      ['==', 'class', 'motorway_link']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fc8',
      'line-width': {
        base: 1.2,
        stops: [
          [12.5, 0],
          [13, 1.5],
          [14, 2.5],
          [20, 11.5]
        ]
      }
    }
  },
  {
    id: 'bridge-link',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      [
        'in',
        'class',
        'primary_link',
        'secondary_link',
        'tertiary_link',
        'trunk_link'
      ]
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [12.5, 0],
          [13, 1.5],
          [14, 2.5],
          [20, 11.5]
        ]
      }
    }
  },
  {
    id: 'bridge-secondary-tertiary',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      ['in', 'class', 'secondary', 'tertiary']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 20]
        ]
      },
      'line-opacity': {
        stops: [
          [16, 0],
          [17, 0.3]
        ]
      }
    }
  },
  {
    id: 'bridge-trunk-primary',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: [
      'all',
      ['==', 'brunnel', 'bridge'],
      ['in', 'class', 'primary', 'trunk']
    ],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fea',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 18]
        ]
      },
      'line-opacity': 0.3
    }
  },
  {
    id: 'bridge-motorway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'bridge'], ['==', 'class', 'motorway']],
    layout: { 'line-join': 'round' },
    paint: {
      'line-color': '#fc8',
      'line-width': {
        base: 1.2,
        stops: [
          [6.5, 0],
          [7, 0.5],
          [20, 18]
        ]
      },
      'line-opacity': 0.3
    }
  },
  {
    id: 'bridge-railway',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'bridge'], ['==', 'class', 'rail']],
    paint: {
      'line-color': '#bbb',
      'line-width': {
        base: 1.4,
        stops: [
          [14, 0.4],
          [15, 0.75],
          [20, 2]
        ]
      }
    }
  },
  {
    id: 'bridge-railway-hatching',
    type: 'line',
    metadata: { 'mapbox:group': '1444849334699.1902' },
    source: 'openmaptiles',
    'source-layer': 'transportation',
    filter: ['all', ['==', 'brunnel', 'bridge'], ['==', 'class', 'rail']],
    paint: {
      'line-color': '#bbb',
      'line-dasharray': [0.2, 8],
      'line-width': {
        base: 1.4,
        stops: [
          [14.5, 0],
          [15, 3],
          [20, 8]
        ]
      }
    }
  },
  {
    id: 'cablecar',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 13,
    filter: ['==', 'class', 'cable_car'],
    layout: { 'line-cap': 'round', visibility: 'visible' },
    paint: {
      'line-color': 'hsl(0, 0%, 70%)',
      'line-width': {
        base: 1,
        stops: [
          [11, 1],
          [19, 2.5]
        ]
      }
    }
  },
  {
    id: 'cablecar-dash',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 13,
    filter: ['==', 'class', 'cable_car'],
    layout: { 'line-cap': 'round', visibility: 'visible' },
    paint: {
      'line-color': 'hsl(0, 0%, 70%)',
      'line-dasharray': [2, 3],
      'line-width': {
        base: 1,
        stops: [
          [11, 3],
          [19, 5.5]
        ]
      }
    }
  },
  {
    id: 'boundary-land-level-4',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'boundary',
    filter: [
      'all',
      ['>=', 'admin_level', 4],
      ['<=', 'admin_level', 8],
      ['!=', 'maritime', 1]
    ],
    layout: { 'line-join': 'round', visibility: 'none' },
    paint: {
      'line-color': '#9e9cab',
      'line-dasharray': [3, 1, 1, 1],
      'line-width': {
        base: 1.4,
        stops: [
          [4, 0.4],
          [5, 1],
          [12, 3]
        ]
      }
    }
  },
  {
    id: 'boundary-land-level-2',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'boundary',
    filter: [
      'all',
      ['==', 'admin_level', 2],
      ['!=', 'maritime', 1],
      ['!=', 'disputed', 1]
    ],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'none'
    },
    paint: {
      'line-color': 'hsl(248, 7%, 66%)',
      'line-width': {
        base: 1,
        stops: [
          [0, 0.6],
          [4, 1.4],
          [5, 2],
          [12, 8]
        ]
      }
    }
  },
  {
    id: 'boundary-land-disputed',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'boundary',
    filter: ['all', ['!=', 'maritime', 1], ['==', 'disputed', 1]],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'none'
    },
    paint: {
      'line-color': 'hsl(248, 7%, 70%)',
      'line-dasharray': [1, 3],
      'line-width': {
        base: 1,
        stops: [
          [0, 0.6],
          [4, 1.4],
          [5, 2],
          [12, 8]
        ]
      }
    }
  },
  {
    id: 'boundary-water',
    type: 'line',
    source: 'openmaptiles',
    'source-layer': 'boundary',
    filter: ['all', ['in', 'admin_level', 2, 4], ['==', 'maritime', 1]],
    layout: {
      'line-cap': 'round',
      'line-join': 'round',
      visibility: 'visible'
    },
    paint: {
      'line-color': 'rgba(154, 189, 214, 1)',
      'line-opacity': {
        stops: [
          [6, 0.6],
          [10, 1]
        ]
      },
      'line-width': {
        base: 1,
        stops: [
          [0, 0.6],
          [4, 1.4],
          [5, 2],
          [12, 8]
        ]
      }
    }
  },
  {
    id: 'water-name-lakeline',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'water_name',
    filter: ['==', '$type', 'LineString'],
    layout: {
      'symbol-placement': 'line',
      'symbol-spacing': 350,
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Italic'],
      'text-letter-spacing': 0.2,
      'text-max-width': 5,
      'text-rotation-alignment': 'map',
      'text-size': 14
    },
    paint: {
      'text-color': '#74aee9',
      'text-halo-color': 'rgba(255,255,255,0.7)',
      'text-halo-width': 1.5
    }
  },
  {
    id: 'water-name-ocean',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'water_name',
    filter: ['all', ['==', '$type', 'Point'], ['==', 'class', 'ocean']],
    layout: {
      'symbol-placement': 'point',
      'symbol-spacing': 350,
      'text-field': '{name:latin}',
      'text-font': ['Noto Sans Italic'],
      'text-letter-spacing': 0.2,
      'text-max-width': 5,
      'text-rotation-alignment': 'map',
      'text-size': 14
    },
    paint: {
      'text-color': '#74aee9',
      'text-halo-color': 'rgba(255,255,255,0.7)',
      'text-halo-width': 1.5
    }
  },
  {
    id: 'water-name-other',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'water_name',
    filter: ['all', ['==', '$type', 'Point'], ['!in', 'class', 'ocean']],
    layout: {
      'symbol-placement': 'point',
      'symbol-spacing': 350,
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Italic'],
      'text-letter-spacing': 0.2,
      'text-max-width': 5,
      'text-rotation-alignment': 'map',
      'text-size': {
        stops: [
          [0, 10],
          [6, 14]
        ]
      },
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(0, 51, 178, 1)',
      'text-halo-color': 'rgba(255, 255, 255, 1)',
      'text-halo-width': 1.5
    }
  },
  {
    id: 'road_oneway',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 15,
    filter: [
      'all',
      ['==', 'oneway', 1],
      [
        'in',
        'class',
        'motorway',
        'trunk',
        'primary',
        'secondary',
        'tertiary',
        'minor',
        'service'
      ]
    ],
    layout: {
      'icon-image': 'oneway',
      'icon-padding': 2,
      'icon-rotate': 90,
      'icon-rotation-alignment': 'map',
      'icon-size': {
        stops: [
          [15, 0.5],
          [19, 1]
        ]
      },
      'symbol-placement': 'line',
      'symbol-spacing': 75,
      visibility: 'visible'
    },
    paint: { 'icon-opacity': 0.5 }
  },
  {
    id: 'road_oneway_opposite',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation',
    minzoom: 15,
    filter: [
      'all',
      ['==', 'oneway', -1],
      [
        'in',
        'class',
        'motorway',
        'trunk',
        'primary',
        'secondary',
        'tertiary',
        'minor',
        'service'
      ]
    ],
    layout: {
      'icon-image': 'oneway',
      'icon-padding': 2,
      'icon-rotate': -90,
      'icon-rotation-alignment': 'map',
      'icon-size': {
        stops: [
          [15, 0.5],
          [19, 1]
        ]
      },
      'symbol-placement': 'line',
      'symbol-spacing': 75,
      visibility: 'visible'
    },
    paint: { 'icon-opacity': 0.5 }
  },
  {
    id: 'highway-name-path',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation_name',
    minzoom: 15.5,
    filter: ['==', 'class', 'path'],
    layout: {
      'symbol-placement': 'line',
      'text-field': '{name:latin} {name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-rotation-alignment': 'map',
      'text-size': {
        base: 1,
        stops: [
          [13, 12],
          [14, 13]
        ]
      }
    },
    paint: {
      'text-color': 'rgba(171, 86, 0, 1)',
      'text-halo-color': '#f8f4f0',
      'text-halo-width': 2
    }
  },
  {
    id: 'highway-name-minor',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation_name',
    minzoom: 15,
    filter: [
      'all',
      ['==', '$type', 'LineString'],
      ['in', 'class', 'minor', 'service', 'track']
    ],
    layout: {
      'symbol-placement': 'line',
      'text-field': '{name:latin} {name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-rotation-alignment': 'map',
      'text-size': {
        base: 1,
        stops: [
          [13, 12],
          [14, 13]
        ]
      },
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(143, 69, 0, 1)',
      'text-halo-blur': 0.5,
      'text-halo-width': 2,
      'text-halo-color': 'rgba(255, 255, 255, 1)'
    }
  },
  {
    id: 'highway-name-major',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation_name',
    minzoom: 12.2,
    filter: ['in', 'class', 'primary', 'secondary', 'tertiary', 'trunk'],
    layout: {
      'symbol-placement': 'line',
      'text-field': '{name:latin} {name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-rotation-alignment': 'map',
      'text-size': {
        base: 1,
        stops: [
          [13, 12],
          [14, 13]
        ]
      },
      visibility: 'visible',
      'symbol-z-order': 'source'
    },
    paint: {
      'text-color': 'rgba(0, 0, 0, 1)',
      'text-halo-blur': 0.5,
      'text-halo-width': 1,
      'text-halo-color': 'rgba(255, 255, 255, 1)'
    }
  },
  {
    id: 'highway-shield-us-interstate',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation_name',
    minzoom: 7,
    filter: [
      'all',
      ['<=', 'ref_length', 6],
      ['==', '$type', 'LineString'],
      ['in', 'network', 'us-interstate']
    ],
    layout: {
      'icon-image': '{network}_{ref_length}',
      'icon-rotation-alignment': 'viewport',
      'icon-size': 1,
      'symbol-placement': {
        base: 1,
        stops: [
          [7, 'point'],
          [7, 'line'],
          [8, 'line']
        ]
      },
      'symbol-spacing': 200,
      'text-field': '{ref}',
      'text-font': ['Noto Sans Regular'],
      'text-rotation-alignment': 'viewport',
      'text-size': 10
    },
    paint: { 'text-color': 'rgba(0, 0, 0, 1)' }
  },
  {
    id: 'highway-shield-us-other',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation_name',
    minzoom: 9,
    filter: [
      'all',
      ['<=', 'ref_length', 6],
      ['==', '$type', 'LineString'],
      ['in', 'network', 'us-highway', 'us-state']
    ],
    layout: {
      'icon-image': '{network}_{ref_length}',
      'icon-rotation-alignment': 'viewport',
      'icon-size': 1,
      'symbol-placement': {
        base: 1,
        stops: [
          [10, 'point'],
          [11, 'line']
        ]
      },
      'symbol-spacing': 200,
      'text-field': '{ref}',
      'text-font': ['Noto Sans Regular'],
      'text-rotation-alignment': 'viewport',
      'text-size': 10
    },
    paint: { 'text-color': 'rgba(0, 0, 0, 1)' }
  },
  {
    id: 'highway-shield',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'transportation_name',
    minzoom: 8,
    filter: [
      'all',
      ['<=', 'ref_length', 6],
      ['==', '$type', 'LineString'],
      ['!in', 'network', 'us-interstate', 'us-highway', 'us-state']
    ],
    layout: {
      'icon-image': 'road_{ref_length}',
      'icon-rotation-alignment': 'viewport',
      'icon-size': 1,
      'symbol-placement': {
        base: 1,
        stops: [
          [10, 'point'],
          [11, 'line']
        ]
      },
      'symbol-spacing': 200,
      'text-field': '{ref}',
      'text-font': ['Noto Sans Regular'],
      'text-rotation-alignment': 'viewport',
      'text-size': 10,
      visibility: 'visible'
    },
    paint: {
      'icon-opacity': {
        stops: [
          [8, 0],
          [9, 1]
        ]
      },
      'text-opacity': {
        stops: [
          [8, 0],
          [9, 1]
        ]
      }
    }
  },
  {
    id: 'waterway-name',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'waterway',
    minzoom: 13,
    filter: ['all', ['==', '$type', 'LineString'], ['has', 'name']],
    layout: {
      'symbol-placement': 'line',
      'symbol-spacing': 350,
      'text-field': '{name:latin} {name:nonlatin}',
      'text-font': ['Noto Sans Italic'],
      'text-letter-spacing': 0.2,
      'text-max-width': 5,
      'text-rotation-alignment': 'map',
      'text-size': 14,
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(2, 72, 255, 1)',
      'text-halo-color': 'rgba(255,255,255,1)',
      'text-halo-width': 1.5,
      'text-halo-blur': 0
    }
  },
  {
    id: 'airport-label-major',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'aerodrome_label',
    minzoom: 10,
    filter: ['all', ['has', 'iata']],
    layout: {
      'icon-image': 'airport_11',
      'icon-size': 1,
      'text-anchor': 'top',
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 9,
      'text-offset': [0, 0.6],
      'text-optional': true,
      'text-padding': 2,
      'text-size': 12,
      visibility: 'visible'
    },
    paint: {
      'text-color': '#666',
      'text-halo-blur': 0.5,
      'text-halo-color': '#ffffff',
      'text-halo-width': 1
    }
  },
  {
    id: 'poi-level-3',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'poi',
    minzoom: 16,
    filter: [
      'all',
      ['==', '$type', 'Point'],
      ['>=', 'rank', 25],
      ['any', ['!has', 'level'], ['==', 'level', 0]]
    ],
    layout: {
      'icon-image': '{class}_11',
      'text-anchor': 'top',
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 9,
      'text-offset': [0, 0.6],
      'text-padding': 20,
      'text-size': 12,
      visibility: 'visible',
      'symbol-spacing': 250,
      'symbol-avoid-edges': false,
      'text-letter-spacing': 0,
      'icon-padding': 2,
      'symbol-placement': 'point',
      'symbol-z-order': 'auto',
      'text-line-height': 1.2,
      'text-allow-overlap': false,
      'text-ignore-placement': false,
      'icon-allow-overlap': false,
      'icon-ignore-placement': false,
      'icon-optional': false
    },
    paint: {
      'text-color': 'rgba(2, 2, 3, 1)',
      'text-halo-blur': 0.5,
      'text-halo-color': 'rgba(232, 227, 227, 1)',
      'text-halo-width': 2,
      'text-translate-anchor': 'map',
      'text-opacity': 1
    }
  },
  {
    id: 'poi-level-2',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'poi',
    minzoom: 15,
    filter: [
      'all',
      ['==', '$type', 'Point'],
      ['<=', 'rank', 24],
      ['>=', 'rank', 15],
      ['any', ['!has', 'level'], ['==', 'level', 0]]
    ],
    layout: {
      'icon-image': '{class}_11',
      'text-anchor': 'top',
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 9,
      'text-offset': [0, 0.6],
      'text-padding': 2,
      'text-size': 12,
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(2, 2, 3, 1)',
      'text-halo-blur': 0.5,
      'text-halo-color': 'rgba(232, 227, 227, 1)',
      'text-halo-width': 1
    }
  },
  {
    id: 'poi-level-1',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'poi',
    minzoom: 14,
    filter: [
      'all',
      ['==', '$type', 'Point'],
      ['<=', 'rank', 14],
      ['has', 'name'],
      ['any', ['!has', 'level'], ['==', 'level', 0]]
    ],
    layout: {
      'icon-image': '{class}_11',
      'text-anchor': 'top',
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 9,
      'text-offset': [0, 0.6],
      'text-padding': 2,
      'text-size': 12,
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(2, 2, 3, 1)',
      'text-halo-blur': 0.5,
      'text-halo-color': 'rgba(232, 227, 227, 1)',
      'text-halo-width': 2
    }
  },
  {
    id: 'poi-railway',
    type: 'symbol',
    source: 'openmaptiles',
    'source-layer': 'poi',
    minzoom: 13,
    filter: [
      'all',
      ['==', '$type', 'Point'],
      ['has', 'name'],
      ['==', 'class', 'railway'],
      ['==', 'subclass', 'station']
    ],
    layout: {
      'icon-allow-overlap': false,
      'icon-ignore-placement': false,
      'icon-image': '{class}_11',
      'icon-optional': false,
      'text-allow-overlap': false,
      'text-anchor': 'top',
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-ignore-placement': false,
      'text-max-width': 9,
      'text-offset': [0, 0.6],
      'text-optional': true,
      'text-padding': 2,
      'text-size': 12
    },
    paint: {
      'text-color': 'rgba(0, 0, 0, 1)',
      'text-halo-blur': 0.5,
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 1
    }
  },
  {
    id: 'place-village',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: ['==', 'class', 'village'],
    layout: {
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 8,
      'text-size': {
        base: 1.2,
        stops: [
          [10, 12],
          [15, 22]
        ]
      },
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(0, 0, 0, 1)',
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 1.2
    }
  },
  {
    id: 'place-town',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: ['==', 'class', 'town'],
    layout: {
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 8,
      'text-size': {
        base: 1.2,
        stops: [
          [10, 14],
          [15, 24]
        ]
      },
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(0, 0, 0, 1)',
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 1.2
    }
  },
  {
    id: 'place-city',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: ['all', ['!=', 'capital', 2], ['==', 'class', 'city']],
    layout: {
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 8,
      'text-size': {
        base: 1.2,
        stops: [
          [7, 14],
          [11, 24]
        ]
      },
      visibility: 'visible'
    },
    paint: {
      'text-color': 'rgba(0, 0, 0, 1)',
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 1.2
    }
  },
  {
    id: 'place-city-capital',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: ['all', ['==', 'capital', 2], ['==', 'class', 'city']],
    layout: {
      'icon-image': 'star_11',
      'icon-size': 0.8,
      'text-anchor': 'left',
      'text-field': '{name:latin}\n{name:nonlatin}',
      'text-font': ['Noto Sans Regular'],
      'text-max-width': 8,
      'text-offset': [0.4, 0],
      'text-size': {
        base: 1.2,
        stops: [
          [7, 14],
          [11, 24]
        ]
      },
      visibility: 'visible'
    },
    paint: {
      'text-color': '#333',
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 1.2
    }
  },
  {
    id: 'place-country-other',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: [
      'all',
      ['==', 'class', 'country'],
      ['>=', 'rank', 3],
      ['!has', 'iso_a2']
    ],
    layout: {
      'text-field': '{name:latin}',
      'text-font': ['Noto Sans Italic'],
      'text-max-width': 6.25,
      'text-size': {
        stops: [
          [3, 11],
          [7, 17]
        ]
      },
      'text-transform': 'uppercase',
      visibility: 'visible'
    },
    paint: {
      'text-color': '#334',
      'text-halo-blur': 1,
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 2
    }
  },
  {
    id: 'place-country-3',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: [
      'all',
      ['==', 'class', 'country'],
      ['>=', 'rank', 3],
      ['has', 'iso_a2']
    ],
    layout: {
      'text-field': '{name:latin}',
      'text-font': ['Noto Sans Bold'],
      'text-max-width': 6.25,
      'text-size': {
        stops: [
          [3, 11],
          [7, 17]
        ]
      },
      'text-transform': 'uppercase',
      visibility: 'visible'
    },
    paint: {
      'text-color': '#334',
      'text-halo-blur': 1,
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 2
    }
  },
  {
    id: 'place-country-2',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: [
      'all',
      ['==', 'class', 'country'],
      ['==', 'rank', 2],
      ['has', 'iso_a2']
    ],
    layout: {
      'text-field': '{name:latin}',
      'text-font': ['Noto Sans Bold'],
      'text-max-width': 6.25,
      'text-size': {
        stops: [
          [2, 11],
          [5, 17]
        ]
      },
      'text-transform': 'uppercase',
      visibility: 'visible'
    },
    paint: {
      'text-color': '#334',
      'text-halo-blur': 1,
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 2
    }
  },
  {
    id: 'place-country-1',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    filter: [
      'all',
      ['==', 'class', 'country'],
      ['==', 'rank', 1],
      ['has', 'iso_a2']
    ],
    layout: {
      'text-field': '{name:latin}',
      'text-font': ['Noto Sans Bold'],
      'text-max-width': 6.25,
      'text-size': {
        stops: [
          [1, 11],
          [4, 17]
        ]
      },
      'text-transform': 'uppercase',
      visibility: 'visible'
    },
    paint: {
      'text-color': '#334',
      'text-halo-blur': 1,
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 2
    }
  },
  {
    id: 'place-continent',
    type: 'symbol',
    metadata: { 'mapbox:group': '1444849242106.713' },
    source: 'openmaptiles',
    'source-layer': 'place',
    maxzoom: 1,
    filter: ['==', 'class', 'continent'],
    layout: {
      'text-field': '{name:latin}',
      'text-font': ['Noto Sans Bold'],
      'text-max-width': 6.25,
      'text-size': 14,
      'text-transform': 'uppercase',
      visibility: 'visible'
    },
    paint: {
      'text-color': '#334',
      'text-halo-blur': 1,
      'text-halo-color': 'rgba(255,255,255,0.8)',
      'text-halo-width': 2
    }
  }
];
