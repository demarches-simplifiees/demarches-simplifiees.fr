function cadastre_active() {
  return $("#map.cadastre").length > 0
}

function get_cadastre(coordinates) {
  if (!cadastre_active())
    return;

  var cadastre;

  $.ajax({
    method: 'post',
    url: '/users/dossiers/' + dossier_id + '/carte/cadastre',
    data: {coordinates: JSON.stringify(coordinates)},
    dataType: 'json',
    async: false
  }).done(function (data) {
    cadastre = data
  });

  return cadastre['cadastres'];
}

function display_cadastre(cadastre_array) {
  if (!cadastre_active())
    return;

  $("#cadastre.list ul").html('');
  new_cadastreLayer();

  if (cadastre_array.length == 1 && cadastre_array[0]['zoom_error'])
    $("#cadastre.list ul").html('<li><b>Merci de dessiner une surface plus petite afin de récupérer les parcelles cadastrales.</b></li>');

  else if (cadastre_array.length > 0) {
    cadastre_array.forEach(function (cadastre) {
      $("#cadastre.list ul").append('<li> Parcelle nº ' + cadastre.numero + ' - Feuille ' + cadastre.code_arr + ' ' + cadastre.section + ' ' + cadastre.feuille+ '</li>');

      cadastreItems.addData(cadastre.geometry);
    });

    cadastreItems.setStyle({
      fillColor: '#8a6d3b',
      weight: 2,
      opacity: 0.3,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
    })
  }
  else
    $("#cadastre.list ul").html('<li>AUCUN</li>');
}

function new_cadastreLayer() {
  if (typeof cadastreItems != 'undefined')
    map.removeLayer(cadastreItems);

  cadastreItems = new L.GeoJSON();
  cadastreItems.addTo(map);
}
