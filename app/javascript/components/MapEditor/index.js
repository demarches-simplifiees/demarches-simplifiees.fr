import React, { useState, useRef, useEffect } from 'react';
import PropTypes from 'prop-types';
import mapboxgl from 'mapbox-gl';
import ReactMapboxGl, { GeoJSONLayer, ZoomControl } from 'react-mapbox-gl';
import DrawControl from 'react-mapbox-gl-draw';
import SwitchMapStyle from './SwitchMapStyle';
import SearchInput from './SearchInput';
import { getJSON, ajax } from '@utils';
import { gpx, kml } from '@tmcw/togeojson/dist/togeojson.es.js';
import ortho from '../MapStyles/ortho.json';
import vector from '../MapStyles/vector.json';
import { polygonCadastresFill, polygonCadastresLine } from './utils';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';

const Map = ReactMapboxGl({});

function filterFeatureCollection(featureCollection, source) {
  return {
    type: 'FeatureCollection',
    features: featureCollection.features.filter(
      (feature) => feature.properties.source === source
    )
  };
}

function noop() {}

function MapEditor({ featureCollection, url, preview }) {
  const drawControl = useRef(null);
  const [style, setStyle] = useState('ortho');
  const [coords, setCoords] = useState([1.7, 46.9]);
  const [zoom, setZoom] = useState([5]);
  const [currentMap, setCurrentMap] = useState({});
  const [bbox, setBbox] = useState(featureCollection.bbox);
  const [importInputs, setImportInputs] = useState([]);
  const mapStyle = style === 'ortho' ? ortho : vector;
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

  const generateId = () => Math.random().toString(20).substr(2, 6);

  const updateImportInputs = (inputs, inputId) => {
    const updatedInputs = inputs.filter((input) => input.id !== inputId);
    setImportInputs(updatedInputs);
  };

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

  const onMapLoad = (map) => {
    setCurrentMap(map);

    drawControl.current.draw.set(
      filterFeatureCollection(featureCollection, 'selection_utilisateur')
    );
  };

  const onCadastresUpdate = (evt) => {
    if (currentMap) {
      currentMap
        .getSource('cadastres-layer')
        .setData(
          filterFeatureCollection(evt.detail.featureCollection, 'cadastre')
        );
    }
  };

  const onFileImport = (e, inputId) => {
    const isGpxFile = e.target.files[0].name.includes('.gpx');
    let reader = new FileReader();
    reader.readAsText(e.target.files[0], 'UTF-8');
    reader.onload = async (event) => {
      let featureCollection;
      isGpxFile
        ? (featureCollection = gpx(
            new DOMParser().parseFromString(event.target.result, 'text/xml')
          ))
        : (featureCollection = kml(
            new DOMParser().parseFromString(event.target.result, 'text/xml')
          ));

      const resultFeatureCollection = await getJSON(
        `${url}/import`,
        featureCollection,
        'post'
      );

      let inputs = [...importInputs];
      const setInputs = inputs.map((input) => {
        if (input.id === inputId) {
          input.disabled = true;
          input.hasValue = true;
          resultFeatureCollection.features.forEach((feature) => {
            if (
              JSON.stringify(feature.geometry) ===
              JSON.stringify(featureCollection.features[0].geometry)
            ) {
              input.featureId = feature.properties.id;
            }
          });
        }
        return input;
      });

      drawControl.current.draw.set(
        filterFeatureCollection(
          resultFeatureCollection,
          'selection_utilisateur'
        )
      );

      updateFeaturesList(resultFeatureCollection.features);
      setImportInputs(setInputs);
      setBbox(resultFeatureCollection.bbox);
    };
  };

  const addInputFile = (e) => {
    e.preventDefault();
    let inputs = [...importInputs];
    inputs.push({
      id: generateId(),
      disabled: false,
      featureId: null,
      hasValue: false
    });
    setImportInputs(inputs);
  };

  const removeInputFile = async (e, inputId) => {
    e.preventDefault();
    const draw = drawControl.current.draw;
    const featureCollection = draw.getAll();
    let inputs = [...importInputs];
    let drawFeatureIdToRemove;
    const inputToRemove = inputs.find((input) => input.id === inputId);

    for (const feature of featureCollection.features) {
      if (inputToRemove.featureId === feature.properties.id) {
        drawFeatureIdToRemove = feature.id;
      }
    }

    if (inputToRemove.featureId) {
      try {
        await getJSON(`${url}/${inputToRemove.featureId}`, null, 'delete');
        draw.delete(drawFeatureIdToRemove).getAll();
      } catch (e) {
        throw new Error(
          `La feature ${inputToRemove.featureId} a déjà été supprimée manuellement`,
          e
        );
      } finally {
        updateImportInputs(inputs, inputId);
      }
    }
    updateImportInputs(inputs, inputId);
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
      <div className="file-import" style={{ marginBottom: '20px' }}>
        <button className="button send primary" onClick={addInputFile}>
          Ajouter un fichier GPX ou KML
        </button>
        <div>
          {importInputs.map((input) => (
            <div key={input.id}>
              <input
                title="Choisir un fichier gpx ou kml"
                style={{ marginTop: '15px' }}
                id={input.id}
                type="file"
                accept=".gpx, .kml"
                disabled={input.disabled}
                onChange={(e) => onFileImport(e, input.id)}
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
          marginBottom: '50px'
        }}
      >
        <SearchInput
          getCoords={(searchTerm) => {
            setCoords(searchTerm);
            setZoom([17]);
          }}
        />
      </div>
      <Map
        onStyleLoad={(map) => onMapLoad(map)}
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
          onDrawCreate={preview ? noop : onDrawCreate}
          onDrawUpdate={preview ? noop : onDrawUpdate}
          onDrawDelete={preview ? noop : onDrawDelete}
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
}

MapEditor.propTypes = {
  featureCollection: PropTypes.shape({
    bbox: PropTypes.array,
    features: PropTypes.array,
    id: PropTypes.number
  }),
  url: PropTypes.string,
  preview: PropTypes.bool
};

export default MapEditor;
