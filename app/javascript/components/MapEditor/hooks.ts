import { useState, useCallback, useEffect } from 'react';
import { getJSON, ajax, fire } from '@utils';
import type { Feature, FeatureCollection, Geometry } from 'geojson';

export const SOURCE_SELECTION_UTILISATEUR = 'selection_utilisateur';
export const SOURCE_CADASTRE = 'cadastre';

export type CreateFeatures = (params: {
  features: Feature<Geometry>[];
  source?: string;
  external?: true;
}) => void;
export type UpdateFatures = (params: {
  features: Feature<Geometry>[];
  source?: string;
  external?: true;
}) => void;
export type DeleteFeatures = (params: {
  features: Feature<Geometry>[];
  source?: string;
  external?: true;
}) => void;

export function useFeatureCollection(
  initialFeatureCollection: FeatureCollection,
  { url, enabled = true }: { url: string; enabled: boolean }
) {
  const [error, onError] = useError();
  const [featureCollection, setFeatureCollection] = useState(
    initialFeatureCollection
  );
  const updateFeatureCollection = useCallback<
    (callback: (features: Feature[]) => Feature[]) => void
  >(
    (callback) => {
      setFeatureCollection(({ features }) => ({
        type: 'FeatureCollection',
        features: callback(features)
      }));
      ajax({ url, type: 'GET' })
        .then(() => fire(document, 'ds:page:update'))
        .catch(() => null);
    },
    [url, setFeatureCollection]
  );

  const addFeatures = useCallback(
    (features: (Feature & { lid?: string })[], external: boolean) => {
      for (const feature of features) {
        if (feature.lid) {
          fire(document, 'map:internal:draw:setId', {
            lid: feature.lid,
            id: feature.properties?.id
          });
          delete feature.lid;
        }
        if (external) {
          if (feature.properties?.source == SOURCE_SELECTION_UTILISATEUR) {
            fire(document, 'map:internal:draw:add', {
              feature: {
                id: feature.properties.id,
                ...feature
              }
            });
          } else {
            fire(document, 'map:internal:cadastre:highlight', {
              cid: feature.properties?.cid,
              highlight: true
            });
          }
        }
      }
    },
    []
  );

  const removeFeatures = useCallback(
    (features: Feature[], external: boolean) => {
      if (external) {
        for (const feature of features) {
          if (feature.properties?.source == SOURCE_SELECTION_UTILISATEUR) {
            fire(document, 'map:internal:draw:delete', { id: feature.id });
          } else {
            fire(document, 'map:internal:cadastre:highlight', {
              cid: feature.properties?.cid,
              highlight: false
            });
          }
        }
      }
    },
    []
  );

  const createFeatures = useCallback<CreateFeatures>(
    async ({
      features,
      source = SOURCE_SELECTION_UTILISATEUR,
      external = false
    }) => {
      if (!enabled) {
        return;
      }
      try {
        const newFeatures: Feature[] = [];
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
        updateFeatureCollection((features) => [...features, ...newFeatures]);
      } catch (error) {
        console.error(error);
        onError('Le polygone dessiné n’est pas valide.');
      }
    },
    [enabled, url, updateFeatureCollection, addFeatures, onError]
  );

  const updateFeatures = useCallback<UpdateFatures>(
    async ({
      features,
      source = SOURCE_SELECTION_UTILISATEUR,
      external = false
    }) => {
      if (!enabled) {
        return;
      }
      try {
        const newFeatures: Feature[] = [];
        for (const feature of features) {
          const id = feature.properties?.id;
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
    [enabled, url, updateFeatureCollection, addFeatures, onError]
  );

  const deleteFeatures = useCallback<DeleteFeatures>(
    async ({ features, external = false }) => {
      if (!enabled) {
        return;
      }
      try {
        const deletedFeatures = [];
        for (const feature of features) {
          const id = feature.properties?.id;
          await getJSON(`${url}/${id}`, null, 'delete');
          deletedFeatures.push(feature);
        }
        removeFeatures(deletedFeatures, external);
        const deletedFeatureIds = deletedFeatures.map(
          ({ properties }) => properties?.id
        );
        updateFeatureCollection((features) =>
          features.filter(
            ({ properties }) => !deletedFeatureIds.includes(properties?.id)
          )
        );
      } catch (error) {
        console.error(error);
        onError('Le polygone n’a pas pu être supprimé.');
      }
    },
    [enabled, url, updateFeatureCollection, removeFeatures, onError]
  );

  return {
    featureCollection,
    error,
    createFeatures,
    updateFeatures,
    deleteFeatures
  };
}

function useError(): [string | undefined, (message: string) => void] {
  const [error, onError] = useState<string | undefined>();
  useEffect(() => {
    const timer = setTimeout(() => onError(undefined), 5000);
    return () => clearTimeout(timer);
  }, [error]);

  return [error, onError];
}
