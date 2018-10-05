import L from 'leaflet';
import $ from 'jquery';

export function qpActive() {
  return $('#map.qp').length > 0;
}

export function getQP(dossierId, coordinates) {
  return $.ajax({
    method: 'post',
    url: `/users/dossiers/${dossierId}/carte/qp`,
    data: { coordinates: JSON.stringify(coordinates) },
    dataType: 'json'
  }).done(({ quartier_prioritaires }) => values(quartier_prioritaires));
}

let qpItems;

export function displayQP(map, qps) {
  if (!qpActive()) return;

  $('#qp.list ul').html('');
  newQPLayer(map);

  if (qps.length > 0) {
    qps.forEach(function(qp) {
      $('#qp.list ul').append('<li>' + qp.commune + ' : ' + qp.nom + '</li>');

      qpItems.addData(qp.geometry);
    });

    qpItems.setStyle({
      fillColor: '#31708f',
      weight: 2,
      opacity: 0.3,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
    });
  } else {
    $('#qp.list ul').html('<li>AUCUN</li>');
  }
}

function newQPLayer(map) {
  if (qpItems) {
    map.removeLayer(qpItems);
  }

  qpItems = new L.GeoJSON();
  qpItems.addTo(map);
}

function values(obj) {
  return Object.keys(obj).map(v => obj[v]);
}
