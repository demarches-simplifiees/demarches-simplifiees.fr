import L from 'leaflet';
import $ from 'jquery';

export function cadastreActive() {
  return $('#map.cadastre').length > 0;
}

export function getCadastre(dossierId, coordinates) {
  return $.ajax({
    method: 'post',
    url: `/users/dossiers/${dossierId}/carte/cadastre`,
    data: { coordinates: JSON.stringify(coordinates) },
    dataType: 'json'
  }).then(({ cadastres }) => cadastres);
}

let cadastreItems;

export function displayCadastre(map, cadastres) {
  if (!cadastreActive()) return;

  $('#cadastre.list ul').html('');
  newCadastreLayer(map);

  if (cadastres.length == 1 && cadastres[0]['zoom_error']) {
    $('#cadastre.list ul').html(
      '<li><b>Merci de dessiner une surface plus petite afin de récupérer les parcelles cadastrales.</b></li>'
    );
  } else if (cadastres.length > 0) {
    cadastres.forEach(function(cadastre) {
      $('#cadastre.list ul').append(
        '<li> Parcelle nº ' +
          cadastre.numero +
          ' - Feuille ' +
          cadastre.code_arr +
          ' ' +
          cadastre.section +
          ' ' +
          cadastre.feuille +
          '</li>'
      );

      cadastreItems.addData(cadastre.geometry);
    });

    cadastreItems.setStyle({
      fillColor: '#8a6d3b',
      weight: 2,
      opacity: 0.3,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
    });
  } else {
    $('#cadastre.list ul').html('<li>AUCUN</li>');
  }
}

function newCadastreLayer(map) {
  if (cadastreItems) {
    map.removeLayer(cadastreItems);
  }

  cadastreItems = new L.GeoJSON();
  cadastreItems.addTo(map);
}
