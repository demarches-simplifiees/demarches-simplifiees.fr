import React, {
  useState,
  useCallback,
  useRef,
  useMemo,
  useEffect
} from 'react';
import PropTypes from 'prop-types';
import mapboxgl from 'mapbox-gl';
import { GeoJSONLayer, ZoomControl } from 'react-mapbox-gl';
import DrawControl from 'react-mapbox-gl-draw';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';

import { getJSON, ajax, fire } from '@utils';

import Mapbox from '../shared/mapbox/Mapbox';
import { getMapStyle } from '../shared/mapbox/styles';
import SwitchMapStyle from '../shared/mapbox/SwitchMapStyle';
import { FlashMessage } from '../shared/FlashMessage';

import ComboAdresseSearch from '../ComboAdresseSearch';
import {
  polygonCadastresFill,
  polygonCadastresLine,
  readGeoFile
} from './utils';
import {
  noop,
  filterFeatureCollection,
  fitBounds,
  generateId,
  useEvent,
  findFeature
} from '../shared/mapbox/utils';

function MapEditor({ featureCollection, url, preview, options }) {
  const drawControl = useRef(null);
  const [currentMap, setCurrentMap] = useState(null);

  const [errorMessage, setErrorMessage] = useState();
  const [style, setStyle] = useState('ortho');
  const [coords, setCoords] = useState([1.7, 46.9]);
  const [zoom, setZoom] = useState([5]);
  const [bbox, setBbox] = useState(featureCollection.bbox);
  const [importInputs, setImportInputs] = useState([]);
  const [cadastresFeatureCollection, setCadastresFeatureCollection] = useState(
    filterFeatureCollection(featureCollection, 'cadastre')
  );
  const mapStyle = useMemo(() => getMapStyle(style, options.layers), [
    style,
    options
  ]);
  const hasCadastres = useMemo(() => options.layers.includes('cadastres'));

  useEffect(() => {
    const timer = setTimeout(() => setErrorMessage(null), 5000);
    return () => clearTimeout(timer);
  }, [errorMessage]);

  const translations = [
    ['.mapbox-gl-draw_line', 'Tracer une ligne'],
    ['.mapbox-gl-draw_polygon', 'Dessiner un polygone'],
    ['.mapbox-gl-draw_point', 'Ajouter un point'],
    ['.mapbox-gl-draw_trash', 'Supprimer']
  ];
  for (const [selector, translation] of translations) {
    const element = document.querySelector(selector);
    if (element) {
      element.setAttribute('title', translation);
    }
  }

  const onFeatureFocus = useCallback(
    ({ detail }) => {
      const { id } = detail;
      const featureCollection = drawControl.current.draw.getAll();
      const feature = findFeature(featureCollection, id);
      if (feature) {
        fitBounds(currentMap, feature);
      }
    },
    [currentMap, drawControl.current]
  );

  const onFeatureUpdate = useCallback(
    async ({ detail }) => {
      const { id, properties } = detail;
      const featureCollection = drawControl.current.draw.getAll();
      const feature = findFeature(featureCollection, id);

      if (feature) {
        getJSON(`${url}/${id}`, { feature: { properties } }, 'patch');
      }
    },
    [url, drawControl.current]
  );

  const updateFeaturesList = useCallback(
    async (features) => {
      const cadastres = features.find(
        ({ geometry }) => geometry.type === 'Polygon'
      );
      await ajax({
        url,
        type: 'get',
        data: cadastres ? 'cadastres=update' : ''
      });
      fire(document, 'ds:page:update');
    },
    [url]
  );

  const onCadastresUpdate = useCallback(({ detail }) => {
    setCadastresFeatureCollection(
      filterFeatureCollection(detail.featureCollection, 'cadastre')
    );
  }, []);

  useEvent('map:feature:focus', onFeatureFocus);
  useEvent('map:feature:update', onFeatureUpdate);
  useEvent('cadastres:update', onCadastresUpdate);

  function setFeatureId(lid, feature) {
    const draw = drawControl.current.draw;
    draw.setFeatureProperty(lid, 'id', feature.properties.id);
  }

  function updateImportInputs(inputs, inputId) {
    const updatedInputs = inputs.filter((input) => input.id !== inputId);
    setImportInputs(updatedInputs);
  }

  async function onDrawCreate({ features }) {
    try {
      for (const feature of features) {
        const data = await getJSON(url, { feature }, 'post');
        setFeatureId(feature.id, data.feature);
      }

      updateFeaturesList(features);
    } catch {
      setErrorMessage('Le polygone dessiné n’est pas valide.');
    }
  }

  async function onDrawUpdate({ features }) {
    try {
      for (const feature of features) {
        const { id } = feature.properties;
        if (id) {
          await getJSON(`${url}/${id}`, { feature }, 'patch');
        } else {
          const data = await getJSON(url, { feature }, 'post');
          setFeatureId(feature.id, data.feature);
        }
      }

      updateFeaturesList(features);
    } catch {
      setErrorMessage('Le polygone dessiné n’est pas valide.');
    }
  }

  async function onDrawDelete({ features }) {
    for (const feature of features) {
      const { id } = feature.properties;
      await getJSON(`${url}/${id}`, null, 'delete');
    }

    updateFeaturesList(features);
  }

  function onMapLoad(map) {
    setCurrentMap(map);

    drawControl.current.draw.set(
      filterFeatureCollection(featureCollection, 'selection_utilisateur')
    );
  }

  const onFileImport = async (e, inputId) => {
    try {
      const featureCollection = await readGeoFile(e.target.files[0]);
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
          resultFeatureCollection.features.forEach((resultFeature) => {
            featureCollection.features.forEach((feature) => {
              if (
                JSON.stringify(resultFeature.geometry) ===
                JSON.stringify(feature.geometry)
              ) {
                input.featureIds.push(resultFeature.properties.id);
              }
            });
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
    } catch {
      setErrorMessage('Le fichier importé contient des polygones invalides.');
    }
  };

  const addInputFile = (e) => {
    e.preventDefault();
    let inputs = [...importInputs];
    inputs.push({
      id: generateId(),
      disabled: false,
      featureIds: [],
      hasValue: false
    });
    setImportInputs(inputs);
  };

  const removeInputFile = async (e, inputId) => {
    e.preventDefault();
    const draw = drawControl.current.draw;
    const featureCollection = draw.getAll();
    let inputs = [...importInputs];
    const inputToRemove = inputs.find((input) => input.id === inputId);

    for (const feature of featureCollection.features) {
      if (inputToRemove.featureIds.includes(feature.properties.id)) {
        const featureToRemove = draw.get(feature.id);
        await getJSON(`${url}/${feature.properties.id}`, null, 'delete');
        draw.delete(feature.id).getAll();
        updateFeaturesList([featureToRemove]);
      }
    }
    updateImportInputs(inputs, inputId);
  };

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
      {errorMessage && (
        <FlashMessage message={errorMessage} level="alert" fixed={true} />
      )}
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
        <ComboAdresseSearch
          placeholder="Rechercher une adresse : saisissez au moins 2 caractères"
          allowInputValues={false}
          onChange={(_, { geometry: { coordinates } }) => {
            setCoords(coordinates);
            setZoom([17]);
          }}
        />
      </div>
      <Mapbox
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
        {hasCadastres ? (
          <GeoJSONLayer
            data={cadastresFeatureCollection}
            fillPaint={polygonCadastresFill}
            linePaint={polygonCadastresLine}
          />
        ) : null}
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
        <SwitchMapStyle style={style} setStyle={setStyle} ign={options.ign} />
        <ZoomControl />
      </Mapbox>
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
  preview: PropTypes.bool,
  options: PropTypes.shape({
    layers: PropTypes.array,
    ign: PropTypes.bool
  })
};

export default MapEditor;
