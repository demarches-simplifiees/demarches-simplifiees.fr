import cadastreLayers from './cadastre-layers';

const IGN_TOKEN = 'rc1egnbeoss72hxvd143tbyk';

function ignServiceURL(layer, format = 'image/png') {
  const url = `https://wxs.ign.fr/${IGN_TOKEN}/geoportail/wmts`;
  const query =
    'service=WMTS&request=GetTile&version=1.0.0&tilematrixset=PM&tilematrix={z}&tilecol={x}&tilerow={y}&style=normal';

  return `${url}?${query}&layer=${layer}&format=${format}`;
}

const OPTIONAL_LAYERS = [
  {
    label: 'UNESCO',
    id: 'unesco',
    layers: [
      ['Aires protégées Géoparcs', 'PROTECTEDAREAS.GP'],
      ['Réserves de biosphère', 'PROTECTEDAREAS.BIOS']
    ]
  },
  {
    label: 'Arrêtés de protection',
    id: 'arretes_protection',
    layers: [
      ['Arrêtés de protection de biotope', 'PROTECTEDAREAS.APB'],
      ['Arrêtés de protection de géotope', 'PROTECTEDAREAS.APG']
    ]
  },
  {
    label: 'Conservatoire du Littoral',
    id: 'conservatoire_littoral',
    layers: [
      [
        'Conservatoire du littoral : parcelles protégées',
        'PROTECTEDAREAS.MNHN.CDL.PARCELS'
      ],
      [
        'Conservatoire du littoral : périmètres d’intervention',
        'PROTECTEDAREAS.MNHN.CDL.PERIMETER'
      ]
    ]
  },
  {
    label: 'Réserves nationales de chasse et de faune sauvage',
    id: 'reserves_chasse_faune_sauvage',
    layers: [
      [
        'Réserves nationales de chasse et de faune sauvage',
        'PROTECTEDAREAS.RNCF'
      ]
    ]
  },
  {
    label: 'Réserves biologiques',
    id: 'reserves_biologiques',
    layers: [['Réserves biologiques', 'PROTECTEDAREAS.RB']]
  },
  {
    label: 'Réserves naturelles',
    id: 'reserves_naturelles',
    layers: [
      ['Réserves naturelles nationales', 'PROTECTEDAREAS.RN'],
      [
        'Périmètres de protection de réserves naturelles',
        'PROTECTEDAREAS.MNHN.RN.PERIMETER'
      ],
      ['Réserves naturelles de Corse', 'PROTECTEDAREAS.RNC'],
      [
        'Réserves naturelles régionales',
        'PROTECTEDSITES.MNHN.RESERVES-REGIONALES'
      ]
    ]
  },
  {
    label: 'Natura 2000',
    id: 'natura_2000',
    layers: [
      ['Sites Natura 2000 (Directive Habitats)', 'PROTECTEDAREAS.SIC'],
      ['Sites Natura 2000 (Directive Oiseaux)', 'PROTECTEDAREAS.ZPS']
    ]
  },
  {
    label: 'Zones humides d’importance internationale',
    id: 'zones_humides',
    layers: [
      ['Zones humides d’importance internationale', 'PROTECTEDAREAS.RAMSAR']
    ]
  },
  {
    label: 'ZNIEFF',
    id: 'znieff',
    layers: [
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 1 (ZNIEFF 1 mer)',
        'PROTECTEDAREAS.ZNIEFF1.SEA'
      ],
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 1 (ZNIEFF 1)',
        'PROTECTEDAREAS.ZNIEFF1'
      ],
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 2 (ZNIEFF 2 mer)',
        'PROTECTEDAREAS.ZNIEFF2.SEA'
      ],
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 2 (ZNIEFF 2)',
        'PROTECTEDAREAS.ZNIEFF2'
      ]
    ]
  },
  {
    label: 'Cadastre',
    id: 'cadastres',
    layers: [['Cadastre', 'CADASTRE']]
  }
];

function buildSources() {
  return Object.fromEntries(
    OPTIONAL_LAYERS.filter(({ id }) => id !== 'cadastres')
      .flatMap(({ layers }) => layers)
      .map(([, code]) => [
        code.toLowerCase().replace(/\./g, '-'),
        rasterSource([ignServiceURL(code)], 'IGN-F/Géoportail/MNHN')
      ])
  );
}

function rasterSource(tiles, attribution) {
  return {
    type: 'raster',
    tiles,
    tileSize: 256,
    attribution,
    minzoom: 0,
    maxzoom: 18
  };
}

export function buildLayers(ids) {
  return OPTIONAL_LAYERS.filter(({ id }) => ids.includes(id))
    .flatMap(({ layers }) => layers)
    .flatMap(([, code]) =>
      code === 'CADASTRE'
        ? cadastreLayers
        : [rasterLayer(code.toLowerCase().replace(/\./g, '-'))]
    );
}

export function rasterLayer(source) {
  return {
    id: source,
    source,
    type: 'raster',
    paint: { 'raster-resampling': 'linear' }
  };
}

export default {
  version: 8,
  metadat: {
    'mapbox:autocomposite': false,
    'mapbox:groups': {
      1444849242106.713: { collapsed: false, name: 'Places' },
      1444849334699.1902: { collapsed: true, name: 'Bridges' },
      1444849345966.4436: { collapsed: false, name: 'Roads' },
      1444849354174.1904: { collapsed: true, name: 'Tunnels' },
      1444849364238.8171: { collapsed: false, name: 'Buildings' },
      1444849382550.77: { collapsed: false, name: 'Water' },
      1444849388993.3071: { collapsed: false, name: 'Land' }
    },
    'mapbox:type': 'template',
    'openmaptiles:mapbox:owner': 'openmaptiles',
    'openmaptiles:mapbox:source:url': 'mapbox://openmaptiles.4qljc88t',
    'openmaptiles:version': '3.x',
    'maputnik:renderer': 'mbgljs'
  },
  center: [0, 0],
  zoom: 1,
  bearing: 0,
  pitch: 0,
  sources: {
    'decoupage-administratif': {
      type: 'vector',
      url:
        'https://openmaptiles.geo.data.gouv.fr/data/decoupage-administratif.json'
    },
    openmaptiles: {
      type: 'vector',
      url: 'https://openmaptiles.geo.data.gouv.fr/data/france-vector.json'
    },
    'photographies-aeriennes': {
      type: 'raster',
      tiles: [
        'https://tiles.geo.api.gouv.fr/photographies-aeriennes/tiles/{z}/{x}/{y}'
      ],
      tileSize: 256,
      attribution: 'Images aériennes © IGN',
      minzoom: 0,
      maxzoom: 19
    },
    cadastre: {
      type: 'vector',
      url: 'https://openmaptiles.geo.data.gouv.fr/data/cadastre.json'
    },
    'plan-ign': rasterSource(
      [ignServiceURL('GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2')],
      'IGN-F/Géoportail'
    ),
    ...buildSources()
  },
  sprite: 'https://openmaptiles.github.io/osm-bright-gl-style/sprite',
  glyphs: 'https://openmaptiles.geo.data.gouv.fr/fonts/{fontstack}/{range}.pbf'
};
