import React, { useState, useRef, useEffect } from 'react';
import PropTypes from 'prop-types';
import mapboxgl from 'mapbox-gl';
import ReactMapboxGl, { GeoJSONLayer, ZoomControl } from 'react-mapbox-gl';
import DrawControl from 'react-mapbox-gl-draw';
import area from '@turf/area';
import SwitchMapStyle from './SwitchMapStyle';
import SearchInput from './SearchInput';
import { fire } from '@utils';
import ortho from './styles/ortho.json';
import vector from './styles/vector.json';
import {
  createFeatureCollection,
  polygonCadastresFill,
  polygonCadastresLine,
  ERROR_GEO_JSON
} from './utils';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';

const Map = ReactMapboxGl({});

const MapEditor = ({ featureCollection: { features, bbox, id } }) => {
  const drawControl = useRef(null);
  const [style, setStyle] = useState('ortho');
  const [coords, setCoords] = useState([1.7, 46.9]);
  const [zoom, setZoom] = useState([5]);
  const [currentMap, setCurrentMap] = useState({});
  let input = document.querySelector(
    `input[data-feature-collection-id="${id}"]`
  );

  let userSelections = features.filter(
    feature => feature.properties.source === 'selection_utilisateur'
  );

  let cadastresFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };

  const constructCadastresFeatureCollection = features => {
    for (let feature of features) {
      switch (feature.properties.source) {
        case 'cadastre':
          cadastresFeatureCollection.features.push(feature);
          break;
      }
    }
  };
  constructCadastresFeatureCollection(features);

  const mapStyle = style === 'ortho' ? ortho : vector;

  const saveFeatureCollection = featuresToSave => {
    const featuresCollection = createFeatureCollection(featuresToSave);
    if (area(featuresCollection) < 300000) {
      input.value = JSON.stringify(featuresCollection);
    } else {
      input.value = ERROR_GEO_JSON;
    }
    fire(input, 'change');
  };

  const onDrawCreate = ({ features }) => {
    const draw = drawControl.current.draw;
    const featureId = features[0].id;
    draw.setFeatureProperty(featureId, 'id', featureId);
    draw.setFeatureProperty(featureId, 'source', 'selection_utilisateur');
    userSelections.push(draw.get(featureId));
    saveFeatureCollection(userSelections);
  };

  const onDrawUpdate = ({ features }) => {
    let featureId = features[0].properties.id;
    userSelections = userSelections.map(selection => {
      if (selection.properties.id === featureId) {
        selection = features[0];
      }
      return selection;
    });
    saveFeatureCollection(userSelections);
  };

  const onDrawDelete = ({ features }) => {
    userSelections = userSelections.filter(
      selection => selection.properties.id !== features[0].properties.id
    );
    saveFeatureCollection(userSelections);
  };

  const onMapLoad = map => {
    setCurrentMap(map);
    if (userSelections.length > 0) {
      userSelections.map((selection, index) => {
        selection.properties.id = index + 1;
        drawControl.current.draw.add(selection);
      });
    }
  };

  const onMapUpdate = evt => {
    if (currentMap) {
      cadastresFeatureCollection.features = [];
      constructCadastresFeatureCollection(
        evt.detail.featureCollection.features
      );
      currentMap
        .getSource('cadastres-layer')
        .setData(cadastresFeatureCollection);
    }
  };

  useEffect(() => {
    addEventListener('map:update', onMapUpdate);
    return () => removeEventListener('map:update', onMapUpdate);
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
  })
};

export default MapEditor;
