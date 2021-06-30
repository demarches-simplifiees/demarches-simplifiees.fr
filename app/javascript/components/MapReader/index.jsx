import React, { useMemo } from 'react';
import ReactMapboxGl, { ZoomControl, GeoJSONLayer } from 'react-mapbox-gl';
import PropTypes from 'prop-types';
import 'mapbox-gl/dist/mapbox-gl.css';

import MapStyleControl, { useMapStyle } from '../shared/mapbox/MapStyleControl';
import {
  filterFeatureCollection,
  filterFeatureCollectionByGeometryType
} from '../shared/mapbox/utils';
import { useMapbox } from './useMapbox';

const Mapbox = ReactMapboxGl({});

const MapReader = ({ featureCollection, options }) => {
  const {
    isSupported,
    onLoad,
    onStyleChange,
    onMouseEnter,
    onMouseLeave
  } = useMapbox(featureCollection);
  const {
    style,
    layers,
    setStyle,
    setLayerEnabled,
    setLayerOpacity
  } = useMapStyle(options.layers, { onStyleChange });

  if (!isSupported) {
    return (
      <p>
        Nous ne pouvons pas afficher la carte car elle est imcompatible avec
        votre navigateur. Nous vous conseillons de le mettre à jour ou utiliser
        les dernières versions de Chrome, Firefox ou Safari
      </p>
    );
  }

  return (
    <Mapbox
      onStyleLoad={(map) => onLoad(map)}
      style={style}
      containerStyle={{ height: '400px' }}
    >
      <SelectionUtilisateurPolygonLayer
        featureCollection={featureCollection}
        onMouseEnter={onMouseEnter}
        onMouseLeave={onMouseLeave}
      />
      <SelectionUtilisateurLineLayer
        featureCollection={featureCollection}
        onMouseEnter={onMouseEnter}
        onMouseLeave={onMouseLeave}
      />
      <SelectionUtilisateurPointLayer
        featureCollection={featureCollection}
        onMouseEnter={onMouseEnter}
        onMouseLeave={onMouseLeave}
      />

      <MapStyleControl
        style={style.id}
        layers={layers}
        setStyle={setStyle}
        setLayerEnabled={setLayerEnabled}
        setLayerOpacity={setLayerOpacity}
      />
      <ZoomControl />
    </Mapbox>
  );
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

function SelectionUtilisateurPolygonLayer({
  featureCollection,
  onMouseEnter,
  onMouseLeave
}) {
  const data = useMemo(
    () =>
      filterFeatureCollectionByGeometryType(
        filterFeatureCollection(featureCollection, 'selection_utilisateur'),
        'Polygon'
      ),
    [featureCollection]
  );

  return (
    <GeoJSONLayer
      data={data}
      fillPaint={polygonSelectionFill}
      linePaint={polygonSelectionLine}
      fillOnMouseEnter={onMouseEnter}
      fillOnMouseLeave={onMouseLeave}
    />
  );
}

function SelectionUtilisateurLineLayer({
  featureCollection,
  onMouseEnter,
  onMouseLeave
}) {
  const data = useMemo(
    () =>
      filterFeatureCollectionByGeometryType(
        filterFeatureCollection(featureCollection, 'selection_utilisateur'),
        'LineString'
      ),
    [featureCollection]
  );
  return (
    <GeoJSONLayer
      data={data}
      linePaint={lineStringSelectionLine}
      lineOnMouseEnter={onMouseEnter}
      lineOnMouseLeave={onMouseLeave}
    />
  );
}

function SelectionUtilisateurPointLayer({
  featureCollection,
  onMouseEnter,
  onMouseLeave
}) {
  const data = useMemo(
    () =>
      filterFeatureCollectionByGeometryType(
        filterFeatureCollection(featureCollection, 'selection_utilisateur'),
        'Point'
      ),
    [featureCollection]
  );
  return (
    <GeoJSONLayer
      data={data}
      circlePaint={pointSelectionFill}
      circleOnMouseEnter={onMouseEnter}
      circleOnMouseLeave={onMouseLeave}
    />
  );
}

SelectionUtilisateurPolygonLayer.propTypes = {
  featureCollection: PropTypes.shape({
    type: PropTypes.string,
    bbox: PropTypes.array,
    features: PropTypes.array
  }),
  onMouseEnter: PropTypes.func,
  onMouseLeave: PropTypes.func
};

SelectionUtilisateurLineLayer.propTypes = {
  featureCollection: PropTypes.shape({
    type: PropTypes.string,
    bbox: PropTypes.array,
    features: PropTypes.array
  }),
  onMouseEnter: PropTypes.func,
  onMouseLeave: PropTypes.func
};

SelectionUtilisateurPointLayer.propTypes = {
  featureCollection: PropTypes.shape({
    type: PropTypes.string,
    bbox: PropTypes.array,
    features: PropTypes.array
  }),
  onMouseEnter: PropTypes.func,
  onMouseLeave: PropTypes.func
};

MapReader.propTypes = {
  featureCollection: PropTypes.shape({
    bbox: PropTypes.array,
    features: PropTypes.array
  }),
  options: PropTypes.shape({ layers: PropTypes.array })
};

export default MapReader;
