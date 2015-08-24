if (typeof L != 'undefined') {
    (function () {
        OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
            attribution: '&copy; Openstreetmap France | &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        });
        mapId = "map_qp";

        position = get_position();

        map = L.map(mapId, {
            center: new L.LatLng(position.lat, position.lon),
            zoom: 13,
            layers: [OSM]
        });
        window.map = map;
        baseMap = {
            "OpenStreetMap": OSM
        };

        L.control.layers(baseMap).addTo(map);

        function loaddraw(data) {
            var qpLayer = L.geoJson(data).addTo(map);
            map.fitBounds(qpLayer.getBounds());

            recup_qp_dessin(data)
        };

        getdraw(ref_dossier);

        function getdraw (ref) {
            $.ajax({
                headers: {'AUTHORIZATION': ''},
                url: 'http://apicarto.coremaps.com/api/v1/data/' + ref + '/geojson',
                datatype: 'json',
                jsonCallback: 'getJson',
                success: loaddraw
            });
        };

        function loadGeoJson(data) {
            map.spin(false);
            var qpLayer = L.geoJson(data, {onEachFeature: onEachFeature, style: style()}).addTo(map);
        };

        function onEachFeature(feature, layer) {
            var anchor = $(location).attr('hash').substring(1);
            if (anchor != "") {
                var qp_select = JSON.parse(anchor);
                if (qp_select.qp.indexOf(feature.properties.code_qp) > -1) {
                    window.geom_inter.index.push(feature.properties.code_qp);
                    window.featureCollection.features.push(feature);
                    layer.setStyle(select_style());
                    map.fitBounds(layer.getBounds());

                }
            }
        };

        function style(feature) {
            return {
                fillColor: '#FC4E2A',
                weight: 1,
                opacity: 1,
                color: 'white',
                dashArray: '0',
                fillOpacity: 0.6
            };
        }

        function recup_qp_dessin(geom){
            /**/
            $.ajax({
                url: 'http://apicarto.coremaps.com/zoneville/api/v1/qp',
                datatype: 'json',
                method: 'POST',
                data: {geom: geom},
                jsonCallback: 'getJson',
                success: function (data) {
                    var qp_supp = "";
                    feature = geom
                    feature.properties = data;

                    for (i = 0; i < data.length; i++) {
                        $.ajax({
                            url: 'http://apicarto.coremaps.com/zoneville/api/beta/qp/mapservice',
                            datatype: 'json',
                            method: 'GET',
                            data: {code: data[i].code_qp},
                            jsonCallback: 'getJson',
                            success: function (data) {

                                loadGeoJson(data);
                            }
                        });
                    }
                }
            });
            /**/
        }

    }).call(this);
}