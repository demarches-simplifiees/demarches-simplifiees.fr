import { QueryClient, QueryFunction } from 'react-query';
import { httpRequest, getConfig } from '@utils';

const API_EDUCATION_QUERY_LIMIT = 5;
const API_ADRESSE_QUERY_LIMIT = 5;

const {
  autocomplete: { api_adresse_url, api_education_url }
} = getConfig();

type QueryKey = readonly [
  scope: string,
  term: string,
  extra: string | undefined
];

function buildURL(scope: string, term: string) {
  term = term.replace(/\(|\)/g, '');
  const params = new URLSearchParams();
  let path = '';

  if (scope == 'adresse') {
    path = `${api_adresse_url}/search`;
    params.set('q', term);
    params.set('limit', `${API_ADRESSE_QUERY_LIMIT}`);
  } else if (scope == 'annuaire-education') {
    path = `${api_education_url}/search`;
    params.set('q', term);
    params.set('rows', `${API_EDUCATION_QUERY_LIMIT}`);
    params.set('dataset', 'fr-en-annuaire-education');
  }

  return `${path}?${params}`;
}

const defaultQueryFn: QueryFunction<unknown, QueryKey> = async ({
  queryKey: [scope, term],
  signal
}) => {
  // BAN will error with queries less then 3 chars long
  if (scope == 'adresse' && term.length < 3) {
    return {
      type: 'FeatureCollection',
      version: 'draft',
      features: [],
      query: term
    };
  }

  const url = buildURL(scope, term);
  return httpRequest(url, { csrf: false, signal }).json();
};

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // we don't really care about global queryFn type
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      queryFn: defaultQueryFn as any
    }
  }
});
