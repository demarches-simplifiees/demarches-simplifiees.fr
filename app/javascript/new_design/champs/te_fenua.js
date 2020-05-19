import {
  createBatimentLayer,
  createDefaultMap,
  createManualZoneLayer,
  createMarkerFeature,
  createMarkerLayer,
  createParcelleLayer,
  createTeFenuaLayer,
  formatArea,
  getBatimentFeatureInfo,
  getCadastreFeatureInfo
} from './te_fenua_lib';
import { Draw, Modify } from 'ol/interaction.js';
import Select from 'ol/interaction/Select.js';
import { GeoJSON } from 'ol/format';
import Geolocation from 'ol/Geolocation';
import Control from 'ol/control/Control';
import { delegate } from '../../shared/utils';
import {
  createEmpty as olCreateEmpty,
  extend as olExtend,
  getCenter,
  isEmpty as olIsEmpty
} from 'ol/extent';

const MAPS = new WeakMap();
let MARKER_PATH = '';

// Initialise la carte TeFenua quand le DOM est prêt
async function initialize() {
  const elements = document.querySelectorAll('.te-fenua');

  window.viewOnMap = viewOnMap;

  if (elements.length) {
    // await loadOpenLayers(false);

    for (let element of elements) {
      let map = displayMap(element, true);
      MAPS.set(element, map);
    }
  }

  delegate('autocomplete:select', '[data-te-fenua-place]', (event) => {
    let map = getMapFromAddress(event.target);
    if (map) {
      if (event.detail.extent) fitExtent(map, event.detail.extent);
      else if (event.detail.point) moveTo(map, event.detail.point);
      if (event.detail.point) {
        const marker = createMarkerFeature(event.detail.point);
        map.markerLayer.getSource().addFeature(marker);
      }
    }
  });
}

function getInputFromMap(mapElement) {
  return mapElement.parentElement.querySelector('input.features');
}

function getMapFromAddress(element) {
  element = element.closest('.te-fenua');
  return MAPS.get(element);
}

// We load leaflet dynamically, ramda and freedraw and assign them to globals.
// Latest freedraw version build needs globals.
// async function loadOpenLayers(editable) {
//   await import('ol').then(ol => console.log(ol));
//   window.OL = await import('ol').then(OL => OL);
//
//   if (editable) {
//     window.R = await import('ramda').then(({ default: R }) => R);
//     await import('leaflet-freedraw/dist/leaflet-freedraw.web.js');
//   }
// }

function getLink(feature) {
  const link = `<button type='button' onclick="window.viewOnMap(this, '${feature.getId()}')"><img alt='Voir sur la carte' src="${MARKER_PATH}" style="width: 12px"></button>`;
  return link;
}

let parcelleToHtml = (html, feature) => {
  const p = feature.getProperties();
  return `${html}\n<li>${getLink(feature)}&nbsp;Parcelle à ${p.commune} n°${
    p.sec_parcelle
  } - ${p.surface_adop} m<sup>2</sup> - ${p.terre}</li>`;
};

let batimentToHtml = (html, feature) => {
  const p = feature.getProperties();
  const area = formatArea(feature.getGeometry());
  const labels = [p.objectid, p.nom, area, p.commune, p.com, p.ile]
    .filter(Boolean)
    .join(' - ');
  return `${html}\n<li>${getLink(feature)}&nbsp;Batiment ${labels}</li>`;
};
let zoneToHtml = (html, feature) => {
  const p = feature.getProperties();
  const area = formatArea(feature.getGeometry());
  const labels = [feature.getId(), area, p.commune, p.ile]
    .filter(Boolean)
    .join(' - ');
  return `${html}\n<li>${getLink(feature)}&nbsp;${labels}</li>`;
};

function getMapFromLocationButton(element) {
  const mapElement = element.closest('.geo-areas').previousElementSibling;
  if (mapElement.getAttribute('class').includes('te-fenua'))
    return MAPS.get(mapElement);
  return undefined;
}

function viewOnMap(element, id) {
  let map = getMapFromLocationButton(element);
  let feature =
    map.batimentsLayer.getSource().getFeatureById(id) ||
    map.parcellesLayer.getSource().getFeatureById(id) ||
    map.zoneManuellesLayer.getSource().getFeatureById(id);
  if (feature) fitExtent(map, feature.getGeometry().getExtent());
}

function getHtml(layer, toHtml, title) {
  let features = layer.getSource().getFeatures();
  if (features.length) {
    const header = `<div class='areas-title'>${title}</div>`;
    const zones = features.reduce(toHtml, '<ul>') + '</ul>';
    return header + zones;
  }
  return '';
}

function centerMapOnLocation(map) {
  const view = map.getView();
  let location = new Geolocation({
    projection: view.getProjection(),
    tracking: true
  });
  location.once('change', () => {
    view.animate({ center: location.getPosition() });
    location.setTracking(false);
  });
}

function centerMap(map) {
  let extent = olCreateEmpty();
  olExtend(extent, map.parcellesLayer.getSource().getExtent());
  olExtend(extent, map.batimentsLayer.getSource().getExtent());
  olExtend(extent, map.zoneManuellesLayer.getSource().getExtent());
  if (olIsEmpty(extent)) centerMapOnLocation(map);
  else fitExtent(map, extent);
}

function moveTo(map, point) {
  map.getView().animate({ center: point });
}

function fitExtent(map, extent) {
  let view = map.getView();
  view.fit(extent, { duration: 2000, maxZoom: 17 });
}

function createControl(map, handler, action, tooltip = 'Bouton') {
  const button = document.createElement('button');
  button.setAttribute('title', tooltip);
  button.setAttribute('type', 'button');
  //button.innerHTML = icon;

  button.addEventListener('click', handler, false);

  const frame = document.createElement('div');
  frame.className = `ol-control-${action} ol-unselectable ol-control`;
  frame.appendChild(button);

  const control = new Control({
    element: frame
  });
  map.addControl(control);
}

function updateInformations(informations, map) {
  informations.innerHTML =
    getHtml(map.parcellesLayer, parcelleToHtml, 'Parcelles') +
    getHtml(map.batimentsLayer, batimentToHtml, 'Batiments') +
    getHtml(map.zoneManuellesLayer, zoneToHtml, 'Zones');
}

function initMap(mapElement, map) {
  function initFeatures(zoneSource, layer) {
    if (zoneSource) {
      const zones = new GeoJSON().readFeatures(zoneSource);
      zones.forEach((f) => layer.getSource().addFeature(f));
    }
  }

  let data = mapElement.getAttribute('data-geo');
  if (data == null) {
    const input = getInputFromMap(mapElement);
    if (input) data = input.value;
  }
  if (data) {
    // récupère la zone d'information des objets selectionnés.
    const informations = mapElement.parentElement.querySelector('.geo-areas');
    // Prépare l'interpréteur GEOJSON.
    const geodata = JSON.parse(data);
    initFeatures(geodata.parcelles, map.parcellesLayer);
    initFeatures(geodata.batiments, map.batimentsLayer);
    initFeatures(geodata.zones_manuelles, map.zoneManuellesLayer);
    updateInformations(informations, map);
  }
}

// add interaction on the map to select parcelles(cadastres), batiments & add manually zones to the map.
function addInteractions(mapElement, map) {
  // récupère la zone d'information des objets selectionnés.
  const informations = mapElement.parentElement.querySelector('.geo-areas');
  // Prépare l'interpréteur GEOJSON.
  const geojson = new GeoJSON();
  // Récupère la vue de carte.
  const mapView = map.getView();
  // champ à remplir avec les zones selectionnées
  let champ = getInputFromMap(mapElement);
  // valeur du champ
  let geodata = champ.value.length > 0 ? JSON.parse(champ.value) : {};
  // layer pour ajouter les zones manuelles
  let zoneManuellesLayer = map.zoneManuellesLayer;
  // entry types : parcelles, batiments, zone_manuelles ?
  const entry_type = new Set(mapElement.getAttribute('data-entry').split(','));
  const add_zone = entry_type.has('zones_manuelles');
  const add_batiment = entry_type.has('batiments');
  const add_parcelle = entry_type.has('parcelles');
  // help bubbles
  const bubbles = {
    add: mapElement.querySelector('.add'),
    add_zone: mapElement.querySelector('.add-zone'),
    add_batiment: mapElement.querySelector('.batiment'),
    add_parcelle: mapElement.querySelector('.parcelle')
  };

  hideHelps();
  let draw, select, modify;

  if (add_zone) {
    bubbles.add.style.display = 'block';
    draw = new Draw({
      source: zoneManuellesLayer.getSource(),
      type: 'Polygon'
    });
    map.addInteraction(draw);
    draw.setActive(false);
    modify = new Modify({ source: zoneManuellesLayer.getSource() });
    map.addInteraction(modify);
    select = new Select({ layers: [zoneManuellesLayer] });
    map.addInteraction(select);
    createControl(map, clickOnAddZone, 'add', 'Ajouter une zone');
    createControl(map, clickOnEffaceZone, 'delete', 'Effacer une zone');
    draw.on('drawend', (e) => {
      bubbles.add_zone.style.display = 'none';
      let source = map.zoneManuellesLayer.getSource();
      let index = source.getFeatures().length + 1;
      let id;
      while (source.getFeatureById((id = `Zone ${index}`)) != null) index++;
      e.feature.setId(id);
      const coord = getCenter(e.feature.getGeometry().getExtent());
      let resolution = mapView.getResolution();
      let projection = mapView.getProjection();
      getCadastreFeatureInfo(coord, resolution, projection).then((pjson) => {
        if (!pjson || pjson.type !== 'FeatureCollection') {
          throw new Error('Invalid response returned');
        }
        // ajoute le nom de la commune et l'il à la zone créé
        const features = geojson.readFeatures(pjson);
        if (features.length) {
          e.feature.setProperties({
            commune: features[0].getProperties().commune,
            ile: features[0].getProperties().ile
          });
        }
        setTimeout(() =>
          updateChampWith('zones_manuelles', map.zoneManuellesLayer)
        );
      });
      // fin de dessin d'une zone ==> désactive l'ajout d'autres zones
      draw.setActive(false);
      // activate lookForBatimentsAndParcelles in a timeout so it doesn't get triggered
      // by the current click
      if (add_parcelle || add_batiment)
        setTimeout(() => addBatimentParcelleInteraction());
    });
  }

  addBatimentParcelleInteraction();

  function hideHelps() {
    Object.keys(bubbles).forEach((b) => (bubbles[b].style.display = 'none'));
  }

  function addBatimentParcelleInteraction() {
    if (add_parcelle || add_batiment)
      map.on('click', lookForBatimentsAndParcelles);
    if (add_parcelle) bubbles.add_parcelle.style.display = 'block';
    if (add_batiment) bubbles.add_batiment.style.display = 'block';
  }

  function clickOnAddZone(e) {
    // bouton ajout d'une zone cliqué
    e.preventDefault();
    // désactivation de la selection de parcelles/batiment
    map.un('click', lookForBatimentsAndParcelles);
    // activation de l'interaction d'ajout de zone manuelle
    draw.setActive(true);
    // désactive l'aide du bouton et affiche l'aide de tracé de zone
    hideHelps();
    bubbles.add_zone.style.display = 'block';
  }

  function clickOnEffaceZone(e) {
    e.preventDefault();
    if (select.getFeatures().getLength() > 0) {
      // area are already selected ==> delete them
      deleteSelectedZones();
    } else {
      // no area selected => next selected object will be deleted
      select.once('select', () => {
        deleteSelectedZones();
      });
    }
  }

  function deleteSelectedZones() {
    select
      .getFeatures()
      .forEach((f) => zoneManuellesLayer.getSource().removeFeature(f));
    select.getFeatures().clear();
    updateChampWith('zones_manuelles', zoneManuellesLayer);
  }

  function updateChampWith(attribute, layer) {
    geodata[attribute] = geojson.writeFeaturesObject(
      layer.getSource().getFeatures()
    );
    champ.value = JSON.stringify(geodata);
    updateInformations(informations, map);
  }

  function addRemoveFeatures(features, layer, attribute, areEquals) {
    features.forEach((f) => {
      //let selected = parcelleLayer.getSource().getFeatureById(f.getId());
      let source = layer.getSource();
      let selected = source
        .getFeatures()
        .find((ft) => areEquals(ft.getProperties(), f.getProperties()));
      if (selected) {
        source.removeFeature(selected);
      } else {
        source.addFeature(f);
      }
    });
    updateChampWith(attribute, layer);
  }

  // look for parcelles under the cursor, and select/unselect according already selected parcelles
  function lookForParcelles(coord, resolution, projection) {
    // const start = new Date();
    getCadastreFeatureInfo(coord, resolution, projection).then((pjson) => {
      // const time = new Date(new Date() - start).getMilliseconds();
      // console.info(`get parcelles time = ${time}`);
      if (!pjson || pjson.type !== 'FeatureCollection') {
        throw new Error('Invalid response returned');
      }
      // Ajoute/Supprime sur la carte les parcelles trouvées par Te Fenua
      const features = geojson.readFeatures(pjson);
      const areEquals = (a, b) => a.id_parcelle === b.id_parcelle;
      addRemoveFeatures(features, map.parcellesLayer, 'parcelles', areEquals);
    });
  }

  // look for batiments under the cursor and if not found look for parcelle
  function lookForBatiments(coord, resolution, projection) {
    // const start = new Date();
    getBatimentFeatureInfo(coord, resolution, projection).then((json) => {
      // const time = new Date(new Date() - start).getMilliseconds();
      // console.info(`get batiments time = ${time}`);
      if (!json || json.type !== 'FeatureCollection') {
        throw new Error('Invalid response returned');
      }
      const features = geojson.readFeatures(json);
      const batimentEquals = (a, b) => a.objectid === b.objectid;
      if (features.length) {
        // Ajoute/Supprime sur la carte les batiments trouvées par Te Fenua
        addRemoveFeatures(
          features,
          map.batimentsLayer,
          'batiments',
          batimentEquals
        );
      } else if (add_parcelle) {
        // pas de batiment trouvé ==> recherche les parcelles au point cliqué
        lookForParcelles(coord, resolution, projection);
      }
    });
  }

  function lookForBatimentsAndParcelles(ev) {
    // Récupère les batiments cliquées.
    let coord = ev.coordinate;
    let resolution = mapView.getResolution();
    let projection = mapView.getProjection();
    if (add_batiment) {
      lookForBatiments(coord, resolution, projection);
    } else {
      lookForParcelles(coord, resolution, projection);
    }
  }
}

function displayMap(mapElement) {
  MARKER_PATH = mapElement.getAttribute('data-marker');

  // Prépare les couches
  const parcellesLayer = createParcelleLayer();
  const batimentsLayer = createBatimentLayer();
  const zoneManuellesLayer = createManualZoneLayer();
  const markerLayer = createMarkerLayer();

  // Prépare la carte OpenLayers.
  let map = createDefaultMap(mapElement, [
    createTeFenuaLayer(),
    parcellesLayer,
    batimentsLayer,
    zoneManuellesLayer,
    markerLayer
  ]);
  map.parcellesLayer = parcellesLayer;
  map.batimentsLayer = batimentsLayer;
  map.zoneManuellesLayer = zoneManuellesLayer;
  map.markerLayer = markerLayer;

  initMap(mapElement, map);

  centerMap(map);

  if (getInputFromMap(mapElement)) addInteractions(mapElement, map);

  return map;
}

addEventListener('DOMContentLoaded', initialize);

/*
addEventListener('carte:update', ({ detail: { selector, data } }) => {
  const element = document.querySelector(selector);
  diplayMap(element, data);
});
*/
