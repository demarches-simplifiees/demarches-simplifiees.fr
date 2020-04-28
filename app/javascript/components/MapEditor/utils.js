export const ERROR_GEO_JSON = '';
export const createFeatureCollection = selectionsUtilisateur => {
  return {
    type: 'FeatureCollection',
    features: selectionsUtilisateur
  };
};

export const polygonCadastresFill = {
  'fill-color': '#EC3323',
  'fill-opacity': 0.3
};

export const polygonCadastresLine = {
  'line-color': 'rgba(255, 0, 0, 1)',
  'line-width': 4,
  'line-dasharray': [1, 1]
};
