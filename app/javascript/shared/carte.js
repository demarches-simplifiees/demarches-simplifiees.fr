import L from 'leaflet';

const MAPS = new WeakMap();

export function drawMap(element, data) {
  const map = initMap(element, data);

  drawCadastre(map, data);
  drawQuartiersPrioritaires(map, data);
  drawParcellesAgricoles(map, data);
  drawUserSelection(map, data);
}

function initMap(element, { position }) {
  if (MAPS.has(element)) {
    return MAPS.get(element);
  } else {
    const map = L.map(element, {
      scrollWheelZoom: false
    }).setView([position.lat, position.lon], position.zoom);

    const loadTilesLayer = process.env.RAILS_ENV != 'test';
    if (loadTilesLayer) {
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(map);
    }

    MAPS.set(element, map);
    return map;
  }
}

function drawUserSelection(map, { selection }) {
  if (selection) {
    const layer = L.geoJSON(selection, {
      style: USER_SELECTION_POLYGON_STYLE
    });

    layer.addTo(map);

    map.fitBounds(layer.getBounds());
  }
}

function drawCadastre(map, { cadastres }) {
  drawLayer(map, cadastres, noEditStyle(CADASTRE_POLYGON_STYLE));
}

function drawQuartiersPrioritaires(map, { quartiersPrioritaires }) {
  drawLayer(map, quartiersPrioritaires, noEditStyle(QP_POLYGON_STYLE));
}

function drawParcellesAgricoles(map, { parcellesAgricoles }) {
  drawLayer(map, parcellesAgricoles, noEditStyle(RPG_POLYGON_STYLE));
}

function drawLayer(map, data, style) {
  if (Array.isArray(data) && data.length > 0) {
    const layer = new L.GeoJSON(undefined, {
      interactive: false,
      style
    });

    for (let { geometry } of data) {
      layer.addData(geometry);
    }

    layer.addTo(map);
  }
}

function noEditStyle(style) {
  return Object.assign({}, style, {
    opacity: 0.7,
    fillOpacity: 0.5,
    color: style.fillColor
  });
}

const POLYGON_STYLE = {
  weight: 2,
  opacity: 0.3,
  color: 'white',
  dashArray: '3',
  fillOpacity: 0.7
};

const CADASTRE_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#8a6d3b'
});

const QP_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#31708f'
});

const RPG_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#31708f'
});

const USER_SELECTION_POLYGON_STYLE = {
  color: 'red'
};
