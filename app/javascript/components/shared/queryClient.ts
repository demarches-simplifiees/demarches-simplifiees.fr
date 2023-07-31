import { QueryClient, QueryFunction } from 'react-query';
import { httpRequest, isNumeric, getConfig } from '@utils';
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

const {
  autocomplete: { api_geo_url, api_adresse_url, api_education_url }
} = getConfig();

type QueryKey = readonly [
  scope: string,
  term: string,
  extra: string | undefined
];

function buildURL(scope: string, term: string, extra?: string) {
  term = term.replace(/\(|\)/g, '');
  const params = new URLSearchParams();
  let path = `${api_geo_url}/${scope}`;

  if (scope == 'adresse') {
    path = `${api_adresse_url}/search`;
    params.set('q', term);
    params.set('limit', `${API_ADRESSE_QUERY_LIMIT}`);
  } else if (scope == 'annuaire-education') {
    path = `${api_education_url}/search`;
    params.set('q', term);
    params.set('rows', `${API_EDUCATION_QUERY_LIMIT}`);
    params.set('dataset', 'fr-en-annuaire-education');
  } else if (scope == 'communes') {
    if (extra) {
      params.set('codeDepartement', extra);
    }
    if (isNumeric(term)) {
      params.set('codePostal', term);
    } else {
      params.set('nom', term);
      params.set('boost', 'population');
    }
    params.set('limit', `${API_GEO_COMMUNES_QUERY_LIMIT}`);
  } else {
    if (isNumeric(term)) {
      params.set('code', term.padStart(2, '0'));
    } else {
      params.set('nom', term);
    }
    if (scope == 'departements') {
      params.set('zone', 'metro,drom,com');
    }
    params.set('limit', `${API_GEO_QUERY_LIMIT}`);
  }

  return `${path}?${params}`;
}

const defaultQueryFn: QueryFunction<unknown, QueryKey> = async ({
  queryKey: [scope, term, extra],
  signal
}) => {
  if (scope == 'pays') {
    return matchSorter(await getPays(signal), term, { keys: ['label'] });
  }

  // BAN will error with queries less then 3 chars long
  if (scope == 'adresse' && term.length < 3) {
    return {
      type: 'FeatureCollection',
      version: 'draft',
      features: [],
      query: term
    };
  }

  const url = buildURL(scope, term, extra);
  return httpRequest(url, { csrf: false, signal }).json();
};

let paysCache: { label: string }[];
async function getPays(signal?: AbortSignal): Promise<{ label: string }[]> {
  if (!paysCache) {
    const data = await httpRequest('/api/pays', { signal }).json<
      typeof paysCache
    >();
    if (data) {
      paysCache = data;
    }
  }
  return paysCache;
}

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // we don't really care about global queryFn type
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      queryFn: defaultQueryFn as any
    }
  }
});
