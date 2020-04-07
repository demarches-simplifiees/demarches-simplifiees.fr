import React from 'react';
import ReactMapboxGl, { ZoomControl, GeoJSONLayer } from 'react-mapbox-gl';
import mapboxgl, { LngLatBounds } from 'mapbox-gl';
import PropTypes from 'prop-types';

const Map = ReactMapboxGl({});

const MapReader = ({ geoData }) => {
  let [selectionCollection, cadastresCollection] = [[], []];

  for (let selection of geoData.selection.coordinates) {
    selectionCollection.push({
      type: 'Feature',
      geometry: {
        type: 'Polygon',
        coordinates: selection
      }
    });
  }

  for (let cadastre of geoData.cadastres) {
    cadastresCollection.push({
      type: 'Feature',
      geometry: {
        type: 'Polygon',
        coordinates: cadastre.geometry.coordinates[0]
      }
    });
  }

  const selectionData = {
    type: 'geojson',
    data: {
      type: 'FeatureCollection',
      features: selectionCollection
    }
  };

  const cadastresData = {
    type: 'geojson',
    data: {
      type: 'FeatureCollection',
      features: cadastresCollection
    }
  };

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

  let bounds = new LngLatBounds();

  for (let selection of selectionCollection) {
    for (let coordinate of selection.geometry.coordinates[0]) {
      bounds.extend(coordinate);
    }
  }
  let [swCoords, neCoords] = [
    Object.values(bounds._sw),
    Object.values(bounds._ne)
  ];
  const boundData = [swCoords, neCoords];

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
        data={selectionData.data}
        fillPaint={polygonSelectionFill}
        linePaint={polygonSelectionLine}
      />
      <GeoJSONLayer
        data={cadastresData.data}
        fillPaint={polygonCadastresFill}
        linePaint={polygonCadastresLine}
      />
      <ZoomControl />
    </Map>
  );
};

MapReader.propTypes = {
  geoData: PropTypes.shape({
    position: PropTypes.object,
    selection: PropTypes.object,
    cadastres: PropTypes.array
  })
};

export default MapReader;
