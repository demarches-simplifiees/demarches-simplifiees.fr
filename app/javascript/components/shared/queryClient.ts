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
  term = encodeURIComponent(term.replace(/\(|\)/g, ''));
  if (scope === 'adresse') {
    return `${api_adresse_url}/search?q=${term}&limit=${API_ADRESSE_QUERY_LIMIT}`;
  } else if (scope === 'annuaire-education') {
    return `${api_education_url}/search?dataset=fr-en-annuaire-education&q=${term}&rows=${API_EDUCATION_QUERY_LIMIT}`;
  } else if (scope === 'communes') {
    const limit = `limit=${API_GEO_COMMUNES_QUERY_LIMIT}`;
    const url = extra
      ? `${api_geo_url}/communes?codeDepartement=${extra}&${limit}&`
      : `${api_geo_url}/communes?${limit}&`;
    if (isNumeric(term)) {
      return `${url}codePostal=${term}`;
    }
    return `${url}nom=${term}&boost=population`;
  } else if (isNumeric(term)) {
    const code = term.padStart(2, '0');
    return `${api_geo_url}/${scope}?code=${code}&limit=${API_GEO_QUERY_LIMIT}`;
  }
  return `${api_geo_url}/${scope}?nom=${term}&limit=${API_GEO_QUERY_LIMIT}`;
}

const defaultQueryFn: QueryFunction<unknown, QueryKey> = async ({
  queryKey: [scope, term, extra],
  signal
}) => {
  if (scope == 'pays') {
    return matchSorter(await getPays(signal), term, { keys: ['label'] });
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
