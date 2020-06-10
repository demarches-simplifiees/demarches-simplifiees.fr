import React, { useState } from 'react';
import ReactMapboxGl, { ZoomControl, GeoJSONLayer } from 'react-mapbox-gl';
import mapboxgl from 'mapbox-gl';
import SwitchMapStyle from './SwitchMapStyle';
import ortho from '../MapStyles/ortho.json';
import orthoCadastre from '../MapStyles/orthoCadastre.json';
import vector from '../MapStyles/vector.json';
import vectorCadastre from '../MapStyles/vectorCadastre.json';
import PropTypes from 'prop-types';

const Map = ReactMapboxGl({});

const MapReader = ({ featureCollection }) => {
  const [style, setStyle] = useState('ortho');
  const hasCadastres = featureCollection.features.find(
    (feature) => feature.properties.source === 'cadastre'
  );
  let mapStyle = style === 'ortho' ? ortho : vector;

  if (hasCadastres) {
    mapStyle = style === 'ortho' ? orthoCadastre : vectorCadastre;
  }

  const [a1, a2, b1, b2] = featureCollection.bbox;
  const boundData = [
    [a1, a2],
    [b1, b2]
  ];

  const cadastresFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };

  const selectionsLineFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };

  const selectionsPolygonFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };

  const selectionsPointFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };

  const polygonSelectionFill = {
    'fill-color': '#EC3323',
    'fill-opacity': 0.5
  };

  const polygonSelectionLine = {
    'line-color': 'rgba(255, 0, 0, 1)',
    'line-width': 4
  };

  const lineStringSelectionLine = {
    'line-color': 'rgba(55, 42, 127, 1.00)',
    'line-width': 3
  };

  const pointSelectionFill = {
    'circle-color': '#EC3323'
  };

  const polygonCadastresFill = {
    'fill-color': '#FAD859',
    'fill-opacity': 0.5
  };

  const polygonCadastresLine = {
    'line-color': 'rgba(156, 160, 144, 255)',
    'line-width': 2,
    'line-dasharray': [1, 1]
  };

  for (let feature of featureCollection.features) {
    switch (feature.properties.source) {
      case 'selection_utilisateur':
        switch (feature.geometry.type) {
          case 'LineString':
            selectionsLineFeatureCollection.features.push(feature);
            break;
          case 'Polygon':
            selectionsPolygonFeatureCollection.features.push(feature);
            break;
          case 'Point':
            selectionsPointFeatureCollection.features.push(feature);
            break;
        }
        break;
      case 'cadastre':
        cadastresFeatureCollection.features.push(feature);
        break;
    }
  }

  if (!mapboxgl.supported()) {
    return (
      <p>
        Nous ne pouvons pas afficher la carte car elle est imcompatible avec
        votre navigateur. Nous vous conseillons de le mettre à jour ou utiliser
        les dernières versions de Chrome, Firefox ou Safari
      </p>
    );
  }

  return (
    <Map
      fitBounds={boundData}
      fitBoundsOptions={{ padding: 100 }}
      style={mapStyle}
      containerStyle={{
        height: '400px',
        width: '100%'
      }}
    >
      <GeoJSONLayer
        data={selectionsPolygonFeatureCollection}
        fillPaint={polygonSelectionFill}
        linePaint={polygonSelectionLine}
      />
      <GeoJSONLayer
        data={selectionsLineFeatureCollection}
        linePaint={lineStringSelectionLine}
      />
      <GeoJSONLayer
        data={selectionsPointFeatureCollection}
        circlePaint={pointSelectionFill}
      />
      <GeoJSONLayer
        data={cadastresFeatureCollection}
        fillPaint={polygonCadastresFill}
        linePaint={polygonCadastresLine}
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
  );
};

MapReader.propTypes = {
  featureCollection: PropTypes.shape({
    type: PropTypes.string,
    bbox: PropTypes.array,
    features: PropTypes.array
  })
};

export default MapReader;
