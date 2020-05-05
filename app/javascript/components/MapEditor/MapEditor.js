import React, { useState, useRef, useEffect } from 'react';
import PropTypes from 'prop-types';
import mapboxgl from 'mapbox-gl';
import ReactMapboxGl, { GeoJSONLayer, ZoomControl } from 'react-mapbox-gl';
import DrawControl from 'react-mapbox-gl-draw';
import SwitchMapStyle from './SwitchMapStyle';
import SearchInput from './SearchInput';
import { getJSON, ajax } from '@utils';
import ortho from './styles/ortho.json';
import vector from './styles/vector.json';
import { polygonCadastresFill, polygonCadastresLine } from './utils';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';

const Map = ReactMapboxGl({});

function filterFeatureCollection(featureCollection, source) {
  return {
    type: 'FeatureCollection',
    features: featureCollection.features.filter(
      feature => feature.properties.source === source
    )
  };
}

const MapEditor = ({ featureCollection, url }) => {
  const drawControl = useRef(null);
  const [style, setStyle] = useState('ortho');
  const [coords, setCoords] = useState([1.7, 46.9]);
  const [zoom, setZoom] = useState([5]);
  const [currentMap, setCurrentMap] = useState({});

  const mapStyle = style === 'ortho' ? ortho : vector;
  const bbox = featureCollection.bbox;
  const cadastresFeatureCollection = filterFeatureCollection(
    featureCollection,
    'cadastre'
  );

  function updateFeaturesList(features) {
    const cadastres = features.find(
      ({ geometry }) => geometry.type === 'Polygon'
    );
    ajax({ url, type: 'get', data: cadastres ? 'cadastres=update' : '' });
  }

  function setFeatureId(lid, feature) {
    const draw = drawControl.current.draw;
    draw.setFeatureProperty(lid, 'id', feature.properties.id);
  }

  async function onDrawCreate({ features }) {
    for (const feature of features) {
      const data = await getJSON(url, { feature }, 'post');
      setFeatureId(feature.id, data.feature);
    }

    updateFeaturesList(features);
  }

  async function onDrawUpdate({ features }) {
    for (const feature of features) {
      let { id } = feature.properties;
      await getJSON(`${url}/${id}`, { feature }, 'patch');
    }

    updateFeaturesList(features);
  }

  async function onDrawDelete({ features }) {
    for (const feature of features) {
      const { id } = feature.properties;
      await getJSON(`${url}/${id}`, null, 'delete');
    }

    updateFeaturesList(features);
  }

  const onMapLoad = map => {
    setCurrentMap(map);

    drawControl.current.draw.set(
      filterFeatureCollection(featureCollection, 'selection_utilisateur')
    );
  };

  const onCadastresUpdate = evt => {
    if (currentMap) {
      currentMap
        .getSource('cadastres-layer')
        .setData(
          filterFeatureCollection(evt.detail.featureCollection, 'cadastre')
        );
    }
  };

  useEffect(() => {
    addEventListener('cadastres:update', onCadastresUpdate);
    return () => removeEventListener('cadastres:update', onCadastresUpdate);
  });

  if (!mapboxgl.supported()) {
    return (
      <p>
        Nous ne pouvons pas afficher notre éditeur de carte car il est
        imcompatible avec votre navigateur. Nous vous conseillons de le mettre à
        jour ou utiliser les dernières versions de Chrome, Firefox ou Safari
      </p>
    );
  }

  return (
    <>
      <div
        style={{
          marginBottom: '62px'
        }}
      >
        <SearchInput
          getCoords={searchTerm => {
            setCoords(searchTerm);
            setZoom([17]);
          }}
        />
      </div>
      <Map
        onStyleLoad={map => onMapLoad(map)}
        fitBounds={bbox}
        fitBoundsOptions={{ padding: 100 }}
        center={coords}
        zoom={zoom}
        style={mapStyle}
        containerStyle={{
          height: '500px'
        }}
      >
        <GeoJSONLayer
          id="cadastres-layer"
          data={cadastresFeatureCollection}
          fillPaint={polygonCadastresFill}
          linePaint={polygonCadastresLine}
        />
        <DrawControl
          ref={drawControl}
          onDrawCreate={onDrawCreate}
          onDrawUpdate={onDrawUpdate}
          onDrawDelete={onDrawDelete}
          displayControlsDefault={false}
          controls={{
            point: true,
            line_string: true,
            polygon: true,
            trash: true
          }}
        />
        <div
          className="style-switch"
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0
          }}
          onClick={() =>
            style === 'ortho' ? setStyle('vector') : setStyle('ortho')
          }
        >
          <SwitchMapStyle isVector={style === 'vector' ? true : false} />
        </div>
        <ZoomControl />
      </Map>
    </>
  );
};

MapEditor.propTypes = {
  featureCollection: PropTypes.shape({
    bbox: PropTypes.array,
    features: PropTypes.array,
    id: PropTypes.number
  }),
  url: PropTypes.string
};

export default MapEditor;
