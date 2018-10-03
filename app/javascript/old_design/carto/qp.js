function qp_active() {
  return $("#map.qp").length > 0
}

function get_qp(coordinates) {
  if (!qp_active())
    return;

  var qp;

  $.ajax({
    method: 'post',
    url: '/users/dossiers/' + dossier_id + '/carte/qp',
    data: {coordinates: JSON.stringify(coordinates)},
    dataType: 'json',
    async: false
  }).done(function (data) {
    qp = data
  });

  return qp['quartier_prioritaires'];
}

function display_qp(qp_list) {
  if (!qp_active())
    return;

  qp_array = jsObject_to_array(qp_list);

  $("#qp.list ul").html('');

  new_qpLayer();

  if (qp_array.length > 0) {
    qp_array.forEach(function (qp) {
      $("#qp.list ul").append('<li>' + qp.commune + ' : ' + qp.nom + '</li>');

      qpItems.addData(qp.geometry);
    });

    qpItems.setStyle({
      fillColor: '#31708f',
      weight: 2,
      opacity: 0.3,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
    })
  }
  else
    $("#qp.list ul").html('<li>AUCUN</li>');
}

function new_qpLayer() {
  if (typeof qpItems != 'undefined')
    map.removeLayer(qpItems);

  qpItems = new L.GeoJSON();
  qpItems.addTo(map);
}
