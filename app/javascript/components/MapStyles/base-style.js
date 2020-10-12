const IGN_TOKEN = 'rc1egnbeoss72hxvd143tbyk';

function ignServiceURL(layer, format = 'image/png') {
  const url = `https://wxs.ign.fr/${IGN_TOKEN}/geoportail/wmts`;
  const query =
    'service=WMTS&request=GetTile&version=1.0.0&tilematrixset=PM&tilematrix={z}&tilecol={x}&tilerow={y}&style=normal';

  return `${url}?${query}&layer=${layer}&format=${format}`;
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
    'protectedareas-gp': rasterSource(
      [ignServiceURL('PROTECTEDAREAS.GP')],
      'IGN-F/Géoportail/MNHN'
    ),
    'protectedareas-pn': rasterSource(
      [ignServiceURL('PROTECTEDAREAS.PN')],
      'IGN-F/Géoportail/MNHN'
    ),
    'protectedareas-pnr': rasterSource(
      [ignServiceURL('PROTECTEDAREAS.PNR')],
      'IGN-F/Géoportail/MNHN'
    ),
    'protectedareas-sic': rasterSource(
      [ignServiceURL('PROTECTEDAREAS.SIC')],
      'IGN-F/Géoportail/MNHN'
    ),
    'protectedareas-zps': rasterSource(
      [ignServiceURL('PROTECTEDAREAS.ZPS')],
      'IGN-F/Géoportail/MNHN'
    )
  },
  sprite: 'https://openmaptiles.github.io/osm-bright-gl-style/sprite',
  glyphs: 'https://openmaptiles.geo.data.gouv.fr/fonts/{fontstack}/{range}.pbf'
};
