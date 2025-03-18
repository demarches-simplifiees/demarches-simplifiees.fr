import Feature from 'ol/Feature';
import OLMap from 'ol/Map';
import Point from 'ol/geom/Point';
import TileLayer from 'ol/layer/Tile';
import TileWMS from 'ol/source/TileWMS';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import View from 'ol/View';
import WMTS from 'ol/source/WMTS';
import WMTSTileGrid from 'ol/tilegrid/WMTS';
import { Circle as CircleStyle, Fill, Stroke, Style } from 'ol/style.js';
import { Icon } from 'ol/style';
import { get as getProjection } from 'ol/proj';
import { defaults as defaultControls } from 'ol/control';
import ScaleLine from 'ol/control/ScaleLine';
import { defaults as olDefaultInteractions } from 'ol/interaction';
import FullScreen from 'ol/control/FullScreen';
import { getArea } from 'ol/sphere';

// TeFenua resolutions before 11th June 2024
// const MAP_RESOLUTIONS = [
//   0.703125, 0.3515625, 0.17578125, 0.087890625, 0.0439453125, 0.02197265625,
//   0.010986328125, 0.0054931640625, 0.00274658203125, 0.001373291015625,
//   0.0006866455078125, 0.0003433227539062, 0.0001716613769531,
//   0.0000858306884766, 0.0000429153442383, 0.0000214576721191,
//   0.0000107288360596, 0.0000053644180298, 0.0000026822090149
// ];

// TeFenua resolution after 11th, June 2024
const MAP_RESOLUTIONS = [
  0.703125, //  0   279541132.00000000
  0.3515625, //  1   139770566.00000000
  0.17578125, //  2    69885283.00000000
  0.087890625, //  3    34942641.50000000
  0.0439453125, //  4    17471320.75000000
  0.0219726562, //  5     8735660.37500000
  0.0109863281, //  6     4367830.18750000
  0.0054931641, //  7     2183915.09375000
  0.002746582, //  8     1091957.54687500
  0.001373291, //  9      545978.77343750
  0.0006866455, // 10      272989.38671875
  0.0003433228, // 11      136494.69335938
  0.0001716614, // 12       68247.34667969
  0.0000858307, // 13       34123.67333984
  0.0000429153, // 14       17061.83666992
  0.0000214577, // 15        8530.91833496
  0.0000107288, // 16        4265.45916748
  0.0000053644, // 17        2132.72958374
  0.0000026822 // 18        1066.36479187
  // 0.0000013411 // 19         533.18239594
];

// Créé une vue de carte par défaut.
// @return {View}

function createDefaultMapView() {
  // http://openlayers.org/en/master/apidoc/ol.View.html
  return new View({
    //center: [-149.57056403160095, -17.54319190979004], // présidence
    center: [-149.911242, -17.493759], // Moorea
    //center: [-149.56771681038853, -17.542614295388], // socredo
    zoom: 18,
    projection: getProjection('EPSG:4326')
  });
}

function getDefaultInteractions() {
  return olDefaultInteractions({
    mouseWheelZoom: true,
    shiftDragZoom: true,
    doubleClickZoom: false,
    onFocusOnly: true
  });
}

// Créé une carte par défaut.
// @param target dom element to fill with the map
// @param layers layers to create in the map
// @return {Map}
export function createDefaultMap(target, layers) {
  // http://openlayers.org/en/master/apidoc/ol.Map.html
  return new OLMap({
    // N'afficher aucun contrôle.
    controls: defaultControls().extend([new ScaleLine(), new FullScreen()]),
    // interaction by default except mouseWheelZoom
    interactions: getDefaultInteractions(),
    // Couches de la carte.
    layers: layers,
    // ID de l'élément où afficher la carte.
    target: target,
    // Charger la carte pendant les animations.
    loadTilesWhileAnimating: true,
    // Charger la carte pendant les interactions.
    loadTilesWhileInteracting: true,
    // Créé la vue par défaut.
    view: createDefaultMapView()
  });
}

// Créé un marqueur.
// @param lonLat
// @return {Feature}
export function createMarkerFeature(lonLat) {
  // http://openlayers.org/en/master/apidoc/ol.Feature.html
  return new Feature({
    geometry: new Point(lonLat),
    style: createMarkerStyle()
  });
}

// Créé le style de marqueur.
// @return {Style}
export function createMarkerStyle() {
  return new Style({
    // http://openlayers.org/en/master/apidoc/ol.style.Icon.html
    image: new Icon({
      anchor: [0.5, 1],
      anchorXUnits: 'fraction',
      anchorYUnits: 'fraction',
      scale: 0.15,
      src: './images/icons/marker.png'
    })
  });
}

// Crée une couche de marqueurs.
// @return {VectorLayer}
export function createMarkerLayer() {
  // http://openlayers.org/en/master/apidoc/ol.layer.Vector.html
  return new VectorLayer({
    source: new VectorSource(),
    zIndex: 100,
    style: new Style({
      image: new Icon({
        anchor: [0.5, 1],
        anchorXUnits: 'fraction',
        anchorYUnits: 'fraction',
        scale: 0.4,
        src:
          'data:image/svg+xml;utf8,' +
          encodeURIComponent(`
          <svg width="50" height="70" viewBox="0 0 50 70" xmlns="http://www.w3.org/2000/svg">
            <path d="M25 0C11.192 0 0 11.415 0 25.5 0 44.625 25 70 25 70s25-25.375 25-44.5C50 11.415 38.808 0 25 0zm0 34.5c-5.247 0-9.5-4.253-9.5-9.5s4.253-9.5 9.5-9.5 9.5 4.253 9.5 9.5-4.253 9.5-9.5 9.5z" fill="#e74c3c"/>
          </svg>
        `)
      })
    })
  });
}

export function createManualZoneLayer() {
  // http://openlayers.org/en/master/apidoc/ol.layer.Vector.html
  return new VectorLayer({
    source: new VectorSource(),
    zIndex: 100,
    style: new Style({
      fill: new Fill({
        color: 'rgba(255, 255, 255, 0.4)'
      }),
      stroke: new Stroke({
        color: '#be1c25',
        width: 2
      }),
      image: new CircleStyle({
        radius: 7,
        fill: new Fill({
          color: '#32dcfa'
        })
      })
    })
  });
}

// Crée la couche des batiments.
// @return {VectorLayer}
export function createBatimentLayer() {
  // http://openlayers.org/en/master/apidoc/ol.layer.Vector.html
  return new VectorLayer({
    source: new VectorSource(),
    style: createBatimentPolygonStyle(),
    zIndex: 20
  });
}

// Crée la couche des parcelles.
// @return {VectorLayer}
export function createParcelleLayer() {
  // http://openlayers.org/en/master/apidoc/ol.layer.Vector.html
  return new VectorLayer({
    source: new VectorSource(),
    style: createParcellePolygonStyle(),
    zIndex: 20
  });
}

// Créé un style de polygone.
// @return {Style}

function createBatimentPolygonStyle() {
  return new Style({
    fill: new Fill({
      color: 'rgba(0,0,0,0.1)'
    }),
    stroke: new Stroke({
      color: '#ce17cf',
      width: 2
    })
  });
}

// Créé un style de polygone.
// @return {Style}

function createParcellePolygonStyle() {
  return new Style({
    fill: new Fill({
      color: 'rgba(255,255,255,0.4)'
    }),
    stroke: new Stroke({
      color: '#00AEAD',
      width: 2
    })
  });
}

// Exécute une requête GetFeatureInfo.
// @param coordinate
// @param resolution
// @param projection
// @param params
// @return {Promise<any | never>}

function getFeatureInfo(coordinate, resolution, projection, params) {
  const url = new TileWMS({
    url: 'https://www.tefenua.gov.pf/api/wms'
  }).getFeatureInfoUrl(coordinate, resolution, projection, params);
  return fetch(url).then((result) => {
    return result.json();
  });
}

// Retourne la parcelle cliquée.
// @param coordinate
// @param resolution
// @param projection
// @return {Promise<any|never>}
export function getBatimentFeatureInfo(coordinate, resolution, projection) {
  const layers = 'TEFENUA:Bati_BatiIndifferencie,TEFENUA:Bati_BatiSpecifique';
  return getFeatureInfo(coordinate, resolution, projection, {
    feature_count: 1,
    layers: layers,
    query_layers: layers,
    info_format: 'application/json',
    buffer: 0
  });
}

// Retourne la parcelle cliquée.
// @param coordinate
// @param resolution
// @param projection
// @return {Promise<any|never>}
export function getCadastreFeatureInfo(coordinate, resolution, projection) {
  const layers = 'TEFENUA:v_Cadastre_Parcelle';
  //const possible = 'TEFENUA:Bati_ConstructionLineaire,TEFENUA:Bati_TerrainSport,TEFENUA:BiensPublics_Communes,TEFENUA:BiensPublics_Etat'
  return getFeatureInfo(coordinate, resolution, projection, {
    feature_count: 1,
    layers: layers,
    query_layers: layers,
    info_format: 'application/json',
    buffer: 0
  });
}

// retourne une feature  décrivant la commune sous le point donné
// @param coordinate point de la recherche
// @param resolution resolution de la carte
// @param projection projection utilisée par la carte
// @returns {Promise<any | never>}
export function getCommuneFeatureInfo(coordinate, resolution, projection) {
  const layers = 'v_Cadastre_Section';
  return getFeatureInfo(coordinate, resolution, projection, {
    feature_count: 1,
    layers: layers,
    query_layers: layers,
    info_format: 'application/json',
    buffer: 0
  });
}

// Retourne les identifiants de la matrice de tuiles.
// @param projection
// @param count
// @return {Array}

function getMatrixIds(projection, count) {
  const matrixIds = [];

  for (let i = 0; i < count; i++) {
    matrixIds.push(i);
  }
  return matrixIds;
}

// Créé la couche du cadastre.
// @return {TileLayer}
export function createCadastreLayer() {
  // http://openlayers.org/en/master/apidoc/ol.layer.Tile.html
  return new TileLayer({
    zIndex: 10,
    opacity: 0.6,
    // http://openlayers.org/en/master/apidoc/ol.source.WMTS.html
    source: new WMTS({
      url: 'https://www.tefenua.gov.pf/api/wmts',
      format: 'image/png',
      layer: 'TEFENUA:CADASTRE',
      style: '',
      matrixSet: 'EPSG:4326',
      projection: getProjection('EPSG:4326'),
      // Configuration des requêtes WMTS
      tileGrid: new WMTSTileGrid({
        extent: [
          -154.722673420735, -23.9062162869884, -134.929174786833,
          -8.78168580956794
        ],
        matrixIds: getMatrixIds('EPSG:4326', MAP_RESOLUTIONS.length),
        origin: [-180, 90],
        resolutions: MAP_RESOLUTIONS,
        tileSize: 256
      })
    })
  });
}

// Créé une couche TeFenua.
// @return {TileLayer}
export function createTeFenuaLayer() {
  // Prépare la couche TeFenua
  // http://openlayers.org/en/master/apidoc/ol.layer.Tile.html
  return new TileLayer({
    zIndex: 2,
    // http://openlayers.org/en/master/apidoc/ol.source.WMTS.html
    source: new WMTS({
      url: 'https://www.tefenua.gov.pf/api/wmts',
      format: 'image/jpeg',
      layer: 'TEFENUA:FOND',
      style: '',
      matrixSet: 'EPSG:4326',
      projection: getProjection('EPSG:4326'),
      // Configuration des requêtes WMTS
      tileGrid: new WMTSTileGrid({
        extent: [-180, -70.20625, 0, 52.70855],
        matrixIds: getMatrixIds('EPSG:4326', MAP_RESOLUTIONS.length),
        origin: [-180, 90],
        resolutions: MAP_RESOLUTIONS,
        tileSize: 256
      })
    })
  });
}

export function formatArea(polygon) {
  const area = getArea(polygon, { projection: getProjection('EPSG:4326') });
  let output;
  if (area > 10000) {
    output = `${Math.round((area / 1000000) * 100) / 100} km<sup>2</sup>`;
  } else {
    output = `${Math.round(area)} m<sup>2</sup>`;
  }
  return output;
}
