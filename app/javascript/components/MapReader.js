import React from 'react';
import ReactMapboxGl, { ZoomControl, GeoJSONLayer } from 'react-mapbox-gl';
import mapboxgl from 'mapbox-gl';
import PropTypes from 'prop-types';

const Map = ReactMapboxGl({});

const MapReader = ({ featureCollection }) => {
  const [a1, a2, b1, b2] = featureCollection.bbox;
  const boundData = [
    [a1, a2],
    [b1, b2]
  ];

  const selectionsFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };
  const cadastresFeatureCollection = {
    type: 'FeatureCollection',
    features: []
  };

  for (let feature of featureCollection.features) {
    switch (feature.properties.source) {
      case 'selection_utilisateur':
        selectionsFeatureCollection.features.push(feature);
        break;
      case 'cadastre':
        cadastresFeatureCollection.features.push(feature);
        break;
    }
  }

  const polygonSelectionFill = {
    'fill-color': '#EC3323',
    'fill-opacity': 0.5
  };

  const polygonSelectionLine = {
    'line-color': 'rgba(255, 0, 0, 1)',
    'line-width': 4
  };

  const polygonCadastresFill = {
    'fill-color': '#9CA090',
    'fill-opacity': 0.5
  };

  const polygonCadastresLine = {
    'line-color': 'rgba(156, 160, 144, 255)',
    'line-width': 2,
    'line-dasharray': [1, 1]
  };

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
      style="https://openmaptiles.geo.data.gouv.fr/styles/osm-bright/style.json"
      containerStyle={{
        height: '400px',
        width: '100%'
      }}
    >
      <GeoJSONLayer
        data={selectionsFeatureCollection}
        fillPaint={polygonSelectionFill}
        linePaint={polygonSelectionLine}
      />
      <GeoJSONLayer
        data={cadastresFeatureCollection}
        fillPaint={polygonCadastresFill}
        linePaint={polygonCadastresLine}
      />
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
