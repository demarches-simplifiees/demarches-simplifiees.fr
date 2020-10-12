import React, { useState, useCallback, useMemo } from 'react';
import ReactMapboxGl, { ZoomControl, GeoJSONLayer } from 'react-mapbox-gl';
import mapboxgl, { Popup } from 'mapbox-gl';
import PropTypes from 'prop-types';

import { getMapStyle, SwitchMapStyle } from '../MapStyles';

import {
  filterFeatureCollection,
  filterFeatureCollectionByGeometryType,
  useEvent,
  findFeature,
  fitBounds,
  getCenter
} from '../shared/map';

const Map = ReactMapboxGl({});

const MapReader = ({ featureCollection, options }) => {
  const [currentMap, setCurrentMap] = useState(null);
  const [style, setStyle] = useState('ortho');
  const cadastresFeatureCollection = useMemo(
    () => filterFeatureCollection(featureCollection, 'cadastre'),
    [featureCollection]
  );
  const selectionsUtilisateurFeatureCollection = useMemo(
    () => filterFeatureCollection(featureCollection, 'selection_utilisateur'),
    [featureCollection]
  );
  const selectionsLineFeatureCollection = useMemo(
    () =>
      filterFeatureCollectionByGeometryType(
        selectionsUtilisateurFeatureCollection,
        'LineString'
      ),
    [selectionsUtilisateurFeatureCollection]
  );
  const selectionsPolygonFeatureCollection = useMemo(
    () =>
      filterFeatureCollectionByGeometryType(
        selectionsUtilisateurFeatureCollection,
        'Polygon'
      ),
    [selectionsUtilisateurFeatureCollection]
  );
  const selectionsPointFeatureCollection = useMemo(
    () =>
      filterFeatureCollectionByGeometryType(
        selectionsUtilisateurFeatureCollection,
        'Point'
      ),
    [selectionsUtilisateurFeatureCollection]
  );
  const hasCadastres = !!cadastresFeatureCollection.length;
  const mapStyle = useMemo(
    () => getMapStyle(style, hasCadastres, options.mnhn),
    [style, options, cadastresFeatureCollection]
  );
  const popup = useMemo(
    () =>
      new Popup({
        closeButton: false,
        closeOnClick: false
      })
  );

  const onMouseEnter = useCallback(
    (event) => {
      const feature = event.features[0];
      if (feature.properties && feature.properties.description) {
        const coordinates = getCenter(feature.geometry, event.lngLat);
        const description = feature.properties.description;
        currentMap.getCanvas().style.cursor = 'pointer';
        popup.setLngLat(coordinates).setHTML(description).addTo(currentMap);
      } else {
        popup.remove();
      }
    },
    [currentMap, popup]
  );

  const onMouseLeave = useCallback(() => {
    currentMap.getCanvas().style.cursor = '';
    popup.remove();
  }, [currentMap, popup]);

  const onFeatureFocus = useCallback(
    ({ detail }) => {
      const feature = findFeature(featureCollection, detail.id);
      if (feature) {
        fitBounds(currentMap, feature);
      }
    },
    [currentMap, featureCollection]
  );

  useEvent('map:feature:focus', onFeatureFocus);

  const [a1, a2, b1, b2] = featureCollection.bbox;
  const boundData = [
    [a1, a2],
    [b1, b2]
  ];

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

  function onMapLoad(map) {
    setCurrentMap(map);
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
      onStyleLoad={(map) => onMapLoad(map)}
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
        fillOnMouseEnter={onMouseEnter}
        fillOnMouseLeave={onMouseLeave}
      />
      <GeoJSONLayer
        data={selectionsLineFeatureCollection}
        linePaint={lineStringSelectionLine}
        lineOnMouseEnter={onMouseEnter}
        lineOnMouseLeave={onMouseLeave}
      />
      <GeoJSONLayer
        data={selectionsPointFeatureCollection}
        circlePaint={pointSelectionFill}
        circleOnMouseEnter={onMouseEnter}
        circleOnMouseLeave={onMouseLeave}
      />
      {hasCadastres ? (
        <GeoJSONLayer
          data={cadastresFeatureCollection}
          fillPaint={polygonCadastresFill}
          linePaint={polygonCadastresLine}
        />
      ) : null}

      <SwitchMapStyle style={style} setStyle={setStyle} ign={options.ign} />
      <ZoomControl />
    </Map>
  );
};

MapReader.propTypes = {
  featureCollection: PropTypes.shape({
    type: PropTypes.string,
    bbox: PropTypes.array,
    features: PropTypes.array
  }),
  options: PropTypes.shape({
    ign: PropTypes.bool,
    mnhn: PropTypes.bool
  })
};

export default MapReader;
