import { useState, useCallback, useEffect } from 'react';
import { httpRequest, fire } from '@utils';
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
  { url }: { url: string }
) {
  const [error, onError] = useError();
  const [featureCollection, setFeatureCollection] = useState(
    initialFeatureCollection
  );
  const refreshFeatureList = useCallback<() => void>(() => {
    httpRequest(url)
      .turbo()
      .catch(() => null);
  }, [url]);

  const updateFeatureCollection = useCallback<
    (callback: (features: Feature[]) => Feature[]) => void
  >(
    (callback) => {
      setFeatureCollection(({ features }) => ({
        type: 'FeatureCollection',
        features: callback(features)
      }));
      refreshFeatureList();
    },
    [refreshFeatureList, setFeatureCollection]
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
      try {
        const newFeatures: Feature[] = [];
        for (const feature of features) {
          const data = await httpRequest(url, {
            method: 'post',
            json: { feature, source }
          }).json<{ feature: Feature & { lid?: string | number } }>();
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
    [url, updateFeatureCollection, addFeatures, onError]
  );

  const updateFeatures = useCallback<UpdateFatures>(
    async ({
      features,
      source = SOURCE_SELECTION_UTILISATEUR,
      external = false
    }) => {
      try {
        const newFeatures: Feature[] = [];
        for (const feature of features) {
          const id = feature.properties?.id;
          if (id) {
            await httpRequest(endpointWithId(url, id), {
              method: 'patch',
              json: { feature }
            }).json();
          } else {
            const data = await httpRequest(url, {
              method: 'post',
              json: { feature, source }
            }).json<{ feature: Feature & { lid?: string | number } }>();
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
        } else {
          refreshFeatureList();
        }
      } catch (error) {
        console.error(error);
        onError('Le polygone dessiné n’est pas valide.');
      }
    },
    [url, refreshFeatureList, updateFeatureCollection, addFeatures, onError]
  );

  const deleteFeatures = useCallback<DeleteFeatures>(
    async ({ features, external = false }) => {
      try {
        const deletedFeatures = [];
        for (const feature of features) {
          const id = feature.properties?.id;
          await httpRequest(endpointWithId(url, id), {
            method: 'delete'
          }).json();
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
    [url, updateFeatureCollection, removeFeatures, onError]
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

// We need this because endoint can have query params. For example with /champs/123?row_id=abc we can't juste concatanate id.
// We want /champs/123/456?row_id=abc not /champs/123?row_id=abc/456
function endpointWithId(endpoint: string, id: string) {
  const url = new URL(endpoint, document.baseURI);
  url.pathname = `${url.pathname}/${id}`;
  return url.toString();
}
