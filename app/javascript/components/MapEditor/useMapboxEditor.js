import { useState, useCallback, useRef, useEffect, useMemo } from 'react';
import mapboxgl from 'mapbox-gl';
import { getJSON, ajax, fire } from '@utils';

import { readGeoFile } from './readGeoFile';
import {
  filterFeatureCollection,
  generateId,
  findFeature,
  getBounds,
  defer
} from '../shared/mapbox/utils';

const SOURCE_SELECTION_UTILISATEUR = 'selection_utilisateur';
const SOURCE_CADASTRE = 'cadastre';

export function useMapboxEditor(
  featureCollection,
  { url, enabled = true, cadastreEnabled = true }
) {
  const [isLoaded, setLoaded] = useState(false);
  const mapRef = useRef();
  const drawRef = useRef();
  const loadedRef = useRef(defer());
  const selectedCadastresRef = useRef(() => new Set());
  const isSupported = useMemo(() => mapboxgl.supported());

  useEffect(() => {
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
  }, [isLoaded]);

  const addEventListener = useCallback((eventName, target, callback) => {
    loadedRef.current.promise.then(() => {
      mapRef.current.on(eventName, target, callback);
    });
    return () => {
      if (mapRef.current) {
        mapRef.current.off(eventName, target, callback);
      }
    };
  }, []);

  const highlightFeature = useCallback((cid, highlight) => {
    if (highlight) {
      selectedCadastresRef.current.add(cid);
    } else {
      selectedCadastresRef.current.delete(cid);
    }
    if (selectedCadastresRef.current.size == 0) {
      mapRef.current.setFilter('parcelle-highlighted', ['in', 'id', '']);
    } else {
      mapRef.current.setFilter('parcelle-highlighted', [
        'in',
        'id',
        ...selectedCadastresRef.current
      ]);
    }
  }, []);

  const fitBounds = useCallback((bbox) => {
    mapRef.current.fitBounds(bbox, { padding: 100 });
  }, []);

  const hoverFeature = useCallback((feature, hover) => {
    if (!selectedCadastresRef.current.has(feature.properties.id)) {
      mapRef.current.setFeatureState(
        {
          source: 'cadastre',
          sourceLayer: 'parcelles',
          id: feature.id
        },
        { hover }
      );
    }
  }, []);

  const addFeatures = useCallback((features, external) => {
    for (const feature of features) {
      if (feature.lid) {
        drawRef.current?.draw.setFeatureProperty(
          feature.lid,
          'id',
          feature.properties.id
        );
        delete feature.lid;
      }
      if (external) {
        if (feature.properties.source == SOURCE_SELECTION_UTILISATEUR) {
          drawRef.current?.draw.add({ id: feature.properties.id, ...feature });
        } else {
          highlightFeature(feature.properties.cid, true);
        }
      }
    }
  }, []);

  const removeFeatures = useCallback((features, external) => {
    if (external) {
      for (const feature of features) {
        if (feature.properties.source == SOURCE_SELECTION_UTILISATEUR) {
          drawRef.current?.draw.delete(feature.id);
        } else {
          highlightFeature(feature.properties.cid, false);
        }
      }
    }
  }, []);

  const onLoad = useCallback(
    (map) => {
      if (!mapRef.current) {
        mapRef.current = map;
        mapRef.current.fitBounds(props.featureCollection.bbox, {
          padding: 100
        });
        onStyleChange();
        setLoaded(true);
        loadedRef.current.resolve();
      }
    },
    [featureCollection]
  );

  const addEventListeners = useCallback((events) => {
    const unsubscribe = Object.entries(
      events
    ).map(([eventName, [target, callback]]) =>
      addEventListener(eventName, target, callback)
    );
    return () => unsubscribe.map((unsubscribe) => unsubscribe());
  }, []);

  const {
    createFeatures,
    updateFeatures,
    deleteFeatures,
    ...props
  } = useFeatureCollection(featureCollection, {
    url,
    enabled: isSupported && enabled,
    addFeatures,
    removeFeatures
  });

  const onStyleChange = useCallback(() => {
    if (mapRef.current) {
      const featureCollection = props.featureCollection;
      if (!cadastreEnabled) {
        drawRef.current?.draw.set(
          filterFeatureCollection(
            featureCollection,
            SOURCE_SELECTION_UTILISATEUR
          )
        );
      }
      selectedCadastresRef.current = new Set(
        filterFeatureCollection(
          featureCollection,
          SOURCE_CADASTRE
        ).features.map(({ properties }) => properties.cid)
      );
      if (selectedCadastresRef.current.size > 0) {
        mapRef.current.setFilter('parcelle-highlighted', [
          'in',
          'id',
          ...selectedCadastresRef.current
        ]);
      }
    }
  }, [props.featureCollection, cadastreEnabled]);

  useExternalEvents(props.featureCollection, {
    fitBounds,
    createFeatures,
    updateFeatures,
    deleteFeatures
  });
  useCadastres(props.featureCollection, {
    addEventListeners,
    hoverFeature,
    createFeatures,
    deleteFeatures,
    enabled: cadastreEnabled
  });

  return {
    isSupported,
    onLoad,
    onStyleChange,
    drawRef,
    createFeatures,
    updateFeatures,
    deleteFeatures,
    ...props,
    ...useImportFiles(props.featureCollection, {
      createFeatures,
      deleteFeatures
    })
  };
}

function useFeatureCollection(
  initialFeatureCollection,
  { url, addFeatures, removeFeatures, enabled = true }
) {
  const [error, onError] = useError();
  const [featureCollection, setFeatureCollection] = useState(
    initialFeatureCollection
  );
  const updateFeatureCollection = useCallback(
    (callback) => {
      setFeatureCollection(({ features }) => ({
        type: 'FeatureCollection',
        features: callback(features)
      }));
      ajax({ url, type: 'GET' })
        .then(() => fire(document, 'ds:page:update'))
        .catch(() => {});
    },
    [setFeatureCollection]
  );

  const createFeatures = useCallback(
    async ({ features, source = SOURCE_SELECTION_UTILISATEUR, external }) => {
      if (!enabled) {
        return;
      }
      try {
        const newFeatures = [];
        for (const feature of features) {
          const data = await getJSON(url, { feature, source }, 'post');
          if (data) {
            if (source == SOURCE_SELECTION_UTILISATEUR) {
              data.feature.lid = feature.id;
            }
            newFeatures.push(data.feature);
          }
        }
        addFeatures(newFeatures, external);
        updateFeatureCollection(
          (features) => [...features, ...newFeatures],
          external
        );
      } catch (error) {
        console.error(error);
        onError('Le polygone dessiné n’est pas valide.');
      }
    },
    [enabled, url, updateFeatureCollection, addFeatures]
  );

  const updateFeatures = useCallback(
    async ({ features, source = SOURCE_SELECTION_UTILISATEUR, external }) => {
      if (!enabled) {
        return;
      }
      try {
        const newFeatures = [];
        for (const feature of features) {
          const { id } = feature.properties;
          if (id) {
            await getJSON(`${url}/${id}`, { feature }, 'patch');
          } else {
            const data = await getJSON(url, { feature, source }, 'post');
            if (data) {
              if (source == SOURCE_SELECTION_UTILISATEUR) {
                data.feature.lid = feature.id;
              }
              newFeatures.push(data.feature);
            }
          }
        }
        if (newFeatures.length > 0) {
          addFeatures(newFeatures, external);
          updateFeatureCollection((features) => [...features, ...newFeatures]);
        }
      } catch (error) {
        console.error(error);
        onError('Le polygone dessiné n’est pas valide.');
      }
    },
    [enabled, url, updateFeatureCollection, addFeatures]
  );

  const deleteFeatures = useCallback(
    async ({ features, external }) => {
      if (!enabled) {
        return;
      }
      try {
        const deletedFeatures = [];
        for (const feature of features) {
          const { id } = feature.properties;
          await getJSON(`${url}/${id}`, null, 'delete');
          deletedFeatures.push(feature);
        }
        removeFeatures(deletedFeatures, external);
        const deletedFeatureIds = deletedFeatures.map(
          ({ properties }) => properties.id
        );
        updateFeatureCollection(
          (features) =>
            features.filter(
              ({ properties }) => !deletedFeatureIds.includes(properties.id)
            ),
          external
        );
      } catch (error) {
        console.error(error);
        onError('Le polygone n’a pas pu être supprimé.');
      }
    },
    [enabled, url, updateFeatureCollection, removeFeatures]
  );

  return {
    featureCollection,
    createFeatures,
    updateFeatures,
    deleteFeatures,
    error
  };
}

function useImportFiles(featureCollection, { createFeatures, deleteFeatures }) {
  const [inputs, setInputs] = useState([]);
  const addInput = useCallback(
    (input) => {
      setInputs((inputs) => [...inputs, input]);
    },
    [setInputs]
  );
  const removeInput = useCallback(
    (inputId) => {
      setInputs((inputs) => inputs.filter((input) => input.id !== inputId));
    },
    [setInputs]
  );

  const onFileChange = useCallback(
    async (event, inputId) => {
      const { features, filename } = await readGeoFile(event.target.files[0]);
      createFeatures({ features, external: true });
      setInputs((inputs) => {
        return inputs.map((input) => {
          if (input.id === inputId) {
            return { ...input, disabled: true, hasValue: true, filename };
          }
          return input;
        });
      });
    },
    [setInputs, createFeatures, featureCollection]
  );

  const addInputFile = useCallback(
    (event) => {
      event.preventDefault();
      addInput({
        id: generateId(),
        disabled: false,
        hasValue: false,
        filename: ''
      });
    },
    [addInput]
  );

  const removeInputFile = useCallback(
    (event, inputId) => {
      event.preventDefault();
      const { filename } = inputs.find((input) => input.id === inputId);
      const features = featureCollection.features.filter(
        (feature) => feature.properties.filename == filename
      );
      deleteFeatures({ features, external: true });
      removeInput(inputId);
    },
    [removeInput, deleteFeatures, featureCollection]
  );

  return {
    inputs,
    onFileChange,
    addInputFile,
    removeInputFile
  };
}

function useExternalEvents(
  featureCollection,
  { fitBounds, createFeatures, updateFeatures, deleteFeatures }
) {
  const onFeatureFocus = useCallback(
    ({ detail }) => {
      const { id, bbox } = detail;
      if (id) {
        const feature = findFeature(featureCollection, id);
        if (feature) {
          fitBounds(getBounds(feature.geometry));
        }
      } else if (bbox) {
        fitBounds(bbox);
      }
    },
    [featureCollection, fitBounds]
  );

  const onFeatureCreate = useCallback(
    ({ detail }) => {
      const { geometry, properties } = detail;

      if (geometry) {
        createFeatures({
          features: [{ geometry, properties }],
          external: true
        });
      }
    },
    [createFeatures]
  );

  const onFeatureUpdate = useCallback(
    ({ detail }) => {
      const { id, properties } = detail;
      const feature = findFeature(featureCollection, id);

      if (feature) {
        feature.properties = { ...feature.properties, ...properties };
        updateFeatures({ features: [feature], external: true });
      }
    },
    [featureCollection, updateFeatures]
  );

  const onFeatureDelete = useCallback(
    ({ detail }) => {
      const { id } = detail;
      const feature = findFeature(featureCollection, id);

      if (feature) {
        deleteFeatures({ features: [feature], external: true });
      }
    },
    [featureCollection, deleteFeatures]
  );

  useEvent('map:feature:focus', onFeatureFocus);
  useEvent('map:feature:create', onFeatureCreate);
  useEvent('map:feature:update', onFeatureUpdate);
  useEvent('map:feature:delete', onFeatureDelete);
}

function useCadastres(
  featureCollection,
  {
    addEventListeners,
    hoverFeature,
    createFeatures,
    deleteFeatures,
    enabled = true
  }
) {
  const hoveredFeature = useRef();

  const onMouseMove = useCallback(
    (event) => {
      if (event.features.length > 0) {
        const feature = event.features[0];
        if (hoveredFeature.current?.id != feature.id) {
          if (hoveredFeature.current) {
            hoverFeature(hoveredFeature.current, false);
          }
          hoveredFeature.current = feature;
          hoverFeature(feature, true);
        }
      }
    },
    [hoverFeature]
  );

  const onMouseLeave = useCallback(() => {
    if (hoveredFeature.current) {
      hoverFeature(hoveredFeature.current, false);
    }
    hoveredFeature.current = null;
  }, [hoverFeature]);

  const onClick = useCallback(
    async (event) => {
      if (event.features.length > 0) {
        const currentId = event.features[0].properties.id;
        const feature = findFeature(
          filterFeatureCollection(featureCollection, SOURCE_CADASTRE),
          currentId,
          'cid'
        );
        if (feature) {
          deleteFeatures({
            features: [feature],
            source: SOURCE_CADASTRE,
            external: true
          });
        } else {
          createFeatures({
            features: event.features,
            source: SOURCE_CADASTRE,
            external: true
          });
        }
      }
    },
    [featureCollection, createFeatures, deleteFeatures]
  );

  useEffect(() => {
    if (enabled) {
      return addEventListeners({
        click: ['parcelles-fill', onClick],
        mousemove: ['parcelles-fill', onMouseMove],
        mouseleave: ['parcelles-fill', onMouseLeave]
      });
    }
  }, [onClick, onMouseMove, onMouseLeave, enabled]);
}

function useError() {
  const [error, onError] = useState();
  useEffect(() => {
    const timer = setTimeout(() => onError(null), 5000);
    return () => clearTimeout(timer);
  }, [error]);

  return [error, onError];
}

export function useEvent(eventName, callback) {
  return useEffect(() => {
    addEventListener(eventName, callback);
    return () => removeEventListener(eventName, callback);
  }, [eventName, callback]);
}
