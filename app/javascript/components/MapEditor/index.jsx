import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ReactMapboxGl, { ZoomControl } from 'react-mapbox-gl';
import DrawControl from 'react-mapbox-gl-draw';
import { MapIcon } from '@heroicons/react/outline';
import 'mapbox-gl/dist/mapbox-gl.css';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';

import MapStyleControl, { useMapStyle } from '../shared/mapbox/MapStyleControl';
import { FlashMessage } from '../shared/FlashMessage';

import ComboAdresseSearch from '../ComboAdresseSearch';
import { useMapboxEditor } from './useMapboxEditor';

const Mapbox = ReactMapboxGl({});

function MapEditor({ featureCollection, url, options, preview }) {
  const [cadastreEnabled, setCadastreEnabled] = useState(false);
  const [coords, setCoords] = useState([1.7, 46.9]);
  const [zoom, setZoom] = useState([5]);
  const {
    isSupported,
    error,
    inputs,
    onLoad,
    onStyleChange,
    onFileChange,
    drawRef,
    createFeatures,
    updateFeatures,
    deleteFeatures,
    addInputFile,
    removeInputFile
  } = useMapboxEditor(featureCollection, {
    url,
    enabled: !preview,
    cadastreEnabled
  });
  const [style, setStyle] = useMapStyle(options.layers, {
    onStyleChange,
    cadastreEnabled
  });

  if (!isSupported) {
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
      {error && <FlashMessage message={error} level="alert" fixed={true} />}
      <div>
        <p style={{ marginBottom: '20px' }}>
          Besoin d&apos;aide ?&nbsp;
          <a
            href="https://doc.demarches-simplifiees.fr/pour-aller-plus-loin/cartographie"
            target="_blank"
            rel="noreferrer"
          >
            consulter les tutoriels video
          </a>
        </p>
      </div>
      <div className="file-import" style={{ marginBottom: '10px' }}>
        <button className="button send primary" onClick={addInputFile}>
          Ajouter un fichier GPX ou KML
        </button>
        <div>
          {inputs.map((input) => (
            <div key={input.id}>
              <input
                title="Choisir un fichier gpx ou kml"
                style={{ marginTop: '15px' }}
                id={input.id}
                type="file"
                accept=".gpx, .kml"
                disabled={input.disabled}
                onChange={(e) => onFileChange(e, input.id)}
              />
              {input.hasValue && (
                <span
                  title="Supprimer le fichier"
                  className="icon refuse"
                  style={{
                    cursor: 'pointer'
                  }}
                  onClick={(e) => removeInputFile(e, input.id)}
                ></span>
              )}
            </div>
          ))}
        </div>
      </div>
      <div
        style={{
          marginBottom: '10px'
        }}
      >
        <ComboAdresseSearch
          className="no-margin"
          placeholder="Rechercher une adresse : saisissez au moins 2 caractères"
          allowInputValues={false}
          onChange={(_, { geometry: { coordinates } }) => {
            setCoords(coordinates);
            setZoom([17]);
          }}
        />
      </div>
      <Mapbox
        onStyleLoad={(map) => onLoad(map)}
        center={coords}
        zoom={zoom}
        style={style}
        containerStyle={{ height: '500px' }}
      >
        {!cadastreEnabled && (
          <DrawControl
            ref={drawRef}
            onDrawCreate={createFeatures}
            onDrawUpdate={updateFeatures}
            onDrawDelete={deleteFeatures}
            displayControlsDefault={false}
            controls={{
              point: true,
              line_string: true,
              polygon: true,
              trash: true
            }}
          />
        )}
        <MapStyleControl style={style.id} setStyle={setStyle} />
        <ZoomControl />
        {options.layers.includes('cadastres') && (
          <div className="cadastres-selection-control mapboxgl-ctrl-group">
            <button
              type="button"
              onClick={() =>
                setCadastreEnabled((cadastreEnabled) => !cadastreEnabled)
              }
              title="Sélectionner les parcelles cadastrales"
              className={cadastreEnabled ? 'on' : ''}
            >
              <MapIcon className="icon-size" />
            </button>
          </div>
        )}
      </Mapbox>
    </>
  );
}

MapEditor.propTypes = {
  featureCollection: PropTypes.shape({
    bbox: PropTypes.array,
    features: PropTypes.array
  }),
  url: PropTypes.string,
  preview: PropTypes.bool,
  options: PropTypes.shape({ layers: PropTypes.array })
};

export default MapEditor;
