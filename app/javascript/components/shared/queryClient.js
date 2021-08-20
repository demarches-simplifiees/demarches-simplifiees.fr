import { QueryClient } from 'react-query';
import { isNumeric } from '@utils';
import { matchSorter } from 'match-sorter';

const API_EDUCATION_QUERY_LIMIT = 5;
const API_GEO_QUERY_LIMIT = 5;
const API_ADRESSE_QUERY_LIMIT = 5;

// When searching for short strings like "mer", le exact match shows up quite far in
// the ordering (~50).
//
// That's why we deliberately fetch a lot of results, and then let the local matching
// (match-sorter) do the work.
//
// NB: 60 is arbitrary, we may add more if needed.
const API_GEO_COMMUNES_QUERY_LIMIT = 60;

const { api_geo_url, api_adresse_url, api_education_url } =
  gon.autocomplete || {};

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: defaultQueryFn
    }
  }
});

function buildURL(scope, term) {
  term = encodeURIComponent(term.replace(/\(|\)/g, ''));
  if (scope === 'adresse') {
    return `${api_adresse_url}/search?q=${term}&limit=${API_ADRESSE_QUERY_LIMIT}`;
  } else if (scope === 'annuaire-education') {
    return `${api_education_url}/search?dataset=fr-en-annuaire-education&q=${term}&rows=${API_EDUCATION_QUERY_LIMIT}`;
  } else if (scope === 'communes') {
    if (isNumeric(term)) {
      return `${api_geo_url}/communes?codePostal=${term}&limit=${API_GEO_COMMUNES_QUERY_LIMIT}`;
    }
    return `${api_geo_url}/communes?nom=${term}&boost=population&limit=${API_GEO_COMMUNES_QUERY_LIMIT}`;
  } else if (isNumeric(term)) {
    const code = term.padStart(2, '0');
    return `${api_geo_url}/${scope}?code=${code}&limit=${API_GEO_QUERY_LIMIT}`;
  }
  return `${api_geo_url}/${scope}?nom=${term}&limit=${API_GEO_QUERY_LIMIT}`;
}

function buildOptions() {
  if (window.AbortController) {
    const controller = new AbortController();
    const signal = controller.signal;
    return [{ signal }, controller];
  }
  return [{}, null];
}

async function defaultQueryFn({ queryKey: [scope, term] }) {
  if (scope == 'pays') {
    return matchSorter(await getPays(), term, { keys: ['nom'] });
  }

  const url = buildURL(scope, term);
  const [options, controller] = buildOptions();
  const promise = fetch(url, options).then((response) => {
    if (response.ok) {
      return response.json();
    }
    throw new Error(`Error fetching from "${scope}" API`);
  });
  promise.cancel = () => controller && controller.abort();
  return promise;
}

let paysCache;
async function getPays() {
  if (!paysCache) {
    paysCache = await fetch('/pays.json').then((response) => response.json());
  }
  return paysCache;
}
