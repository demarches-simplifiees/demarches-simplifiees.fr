import type {
  LayerSpecification,
  RasterLayerSpecification,
  RasterSourceSpecification,
  StyleSpecification
} from 'maplibre-gl';
import invariant from 'tiny-invariant';

import { layers as cadastreLayers } from './layers/cadastre.ts';
import { layers as rpgLayers } from './layers/rpg.ts';

function ignServiceURL(layer: string, style: string, format = 'image/png') {
  const url = `https://data.geopf.fr/wmts`;
  const query =
    'service=WMTS&request=GetTile&version=1.0.0&tilematrixset=PM&tilematrix={z}&tilecol={x}&tilerow={y}';

  return `${url}?${query}&layer=${layer}&format=${format}&style=${style}`;
}

const OPTIONAL_LAYERS: { label: string; id: string; layers: string[][] }[] = [
  {
    label: 'UNESCO',
    id: 'unesco',
    layers: [
      ['Aires protégées Géoparcs', 'PROTECTEDAREAS.GP', 'normal'],
      ['Réserves de biosphère', 'PROTECTEDAREAS.BIOS', 'PROTECTEDAREAS.BIOS']
    ]
  },
  {
    label: 'Arrêtés de protection',
    id: 'arretes_protection',
    layers: [
      [
        'Arrêtés de protection de biotope',
        'PROTECTEDAREAS.APB',
        'PROTECTEDAREAS.APB'
      ],
      ['Arrêtés de protection de géotope', 'PROTECTEDAREAS.APG', 'normal']
    ]
  },
  {
    label: 'Conservatoire du Littoral',
    id: 'conservatoire_littoral',
    layers: [
      [
        'Conservatoire du littoral : parcelles protégées',
        'PROTECTEDAREAS.MNHN.CDL.PARCELS',
        'PROTECTEDAREAS.MNHN.CDL.PARCELS'
      ],
      [
        'Conservatoire du littoral : périmètres d’intervention',
        'PROTECTEDAREAS.MNHN.CDL.PERIMETER',
        'normal'
      ]
    ]
  },
  {
    label: 'Réserves nationales de chasse et de faune sauvage',
    id: 'reserves_chasse_faune_sauvage',
    layers: [
      [
        'Réserves nationales de chasse et de faune sauvage',
        'PROTECTEDAREAS.RNCF',
        'normal'
      ]
    ]
  },
  {
    label: 'Réserves biologiques',
    id: 'reserves_biologiques',
    layers: [['Réserves biologiques', 'PROTECTEDAREAS.RB', 'normal']]
  },
  {
    label: 'Réserves naturelles',
    id: 'reserves_naturelles',
    layers: [
      [
        'Réserves naturelles nationales',
        'PROTECTEDAREAS.RN',
        'PROTECTEDAREAS.RN'
      ],
      [
        'Périmètres de protection de réserves naturelles',
        'PROTECTEDAREAS.MNHN.RN.PERIMETER',
        'normal'
      ],
      [
        'Réserves naturelles de Corse',
        'PROTECTEDAREAS.RNC',
        'PROTECTEDAREAS.RNC'
      ],
      [
        'Réserves naturelles régionales',
        'PROTECTEDSITES.MNHN.RESERVES-REGIONALES',
        'PROTECTEDSITES.MNHN.RESERVES-REGIONALES'
      ]
    ]
  },
  {
    label: 'Natura 2000',
    id: 'natura_2000',
    layers: [
      [
        'Sites Natura 2000 (Directive Habitats)',
        'PROTECTEDAREAS.SIC',
        'PROTECTEDAREAS.SIC'
      ],
      [
        'Sites Natura 2000 (Directive Oiseaux)',
        'PROTECTEDAREAS.ZPS',
        'PROTECTEDAREAS.ZPS'
      ]
    ]
  },
  {
    label: 'Zones humides d’importance internationale',
    id: 'zones_humides',
    layers: [
      [
        'Zones humides d’importance internationale',
        'PROTECTEDAREAS.RAMSAR',
        'PROTECTEDAREAS.RAMSAR'
      ]
    ]
  },
  {
    label: 'ZNIEFF',
    id: 'znieff',
    layers: [
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 1 (ZNIEFF 1 mer)',
        'PROTECTEDAREAS.ZNIEFF1.SEA',
        'normal'
      ],
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 1 (ZNIEFF 1)',
        'PROTECTEDAREAS.ZNIEFF1',
        'PROTECTEDAREAS.ZNIEFF1'
      ],
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 2 (ZNIEFF 2 mer)',
        'PROTECTEDAREAS.ZNIEFF2.SEA',
        'normal'
      ],
      [
        'Zones naturelles d’intérêt écologique faunistique et floristique de type 2 (ZNIEFF 2)',
        'PROTECTEDAREAS.ZNIEFF2',
        'PROTECTEDAREAS.ZNIEFF2'
      ]
    ]
  },
  {
    label: 'Cadastre',
    id: 'cadastres',
    layers: [
      ['Cadastre', 'CADASTRE', 'DECALAGE DE LA REPRESENTATION CADASTRALE']
    ]
  },
  {
    label: 'RPG',
    id: 'rpg',
    layers: [['RPG', 'RPG', 'DECALAGE DE LA REPRESENTATION CADASTRALE']]
  }
];

function buildSources() {
  return Object.fromEntries(
    OPTIONAL_LAYERS.filter(({ id }) => id != 'cadastres' && id != 'rpg')
      .flatMap(({ layers }) => layers)
      .map(([, code, style]) => [
        getLayerCode(code),
        rasterSource([ignServiceURL(code, style)], 'IGN-F/Géoportail/MNHN')
      ])
  );
}

function rasterSource(
  tiles: string[],
  attribution: string
): RasterSourceSpecification {
  return {
    type: 'raster',
    tiles,
    tileSize: 256,
    attribution,
    minzoom: 0,
    maxzoom: 18
  };
}

function rasterLayer(
  source: string,
  opacity: number
): RasterLayerSpecification {
  return {
    id: source,
    source,
    type: 'raster',
    paint: { 'raster-resampling': 'linear', 'raster-opacity': opacity }
  };
}

export function buildOptionalLayers(
  ids: string[],
  opacity: Record<string, number>
): LayerSpecification[] {
  return OPTIONAL_LAYERS.filter(({ id }) => ids.includes(id))
    .flatMap(({ layers, id }) =>
      layers.map(([, code]) => [code, opacity[id] / 100] as const)
    )
    .flatMap(([code, opacity]) => {
      if (code == 'CADASTRE') {
        return cadastreLayers;
      } else if (code == 'RPG') {
        return rpgLayers;
      }
      return [rasterLayer(getLayerCode(code), opacity)];
    });
}

export const NBS = ' ' as const;

export function getLayerName(layer: string): string {
  const name = OPTIONAL_LAYERS.find(({ id }) => id == layer);
  invariant(name, `Layer "${layer}" not found`);
  return name.label.replace(/\s/g, NBS);
}

function getLayerCode(code: string) {
  return code.toLowerCase().replace(/\./g, '-');
}

export const style: StyleSpecification = {
  version: 8,
  metadata: {
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
      url: 'https://openmaptiles.geo.data.gouv.fr/data/decoupage-administratif.json'
    },
    openmaptiles: {
      type: 'vector',
      url: 'https://openmaptiles.geo.data.gouv.fr/data/france-vector.json'
    },
    'photographies-aeriennes': rasterSource(
      [ignServiceURL('ORTHOIMAGERY.ORTHOPHOTOS', 'normal', 'image/jpeg')],
      'IGN-F/Géoportail'
    ),
    cadastre: {
      type: 'vector',
      url: 'https://openmaptiles.geo.data.gouv.fr/data/cadastre.json'
    },
    'plan-ign': rasterSource(
      [ignServiceURL('GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2', 'normal')],
      'IGN-F/Géoportail'
    ),
    rpg: {
      type: 'vector',
      url: 'pmtiles://https://object.data.gouv.fr/pmtiles/rpg_2023.pmtiles'
    },
    ...buildSources()
  },
  sprite: 'https://openmaptiles.github.io/osm-bright-gl-style/sprite',
  glyphs: 'https://openmaptiles.geo.data.gouv.fr/fonts/{fontstack}/{range}.pbf',
  layers: []
};
