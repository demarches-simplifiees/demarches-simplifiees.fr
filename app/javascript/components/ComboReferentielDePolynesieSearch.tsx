import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

type ReferentielDePolynesieResult = {
  name: string;
  id: string;
  domain: string;
};

function transformResults(_: unknown, result: unknown) {
  return result as ReferentielDePolynesieResult[];
}

export default function ComboReferentielDePolynesieResultSearch(
  props: ComboSearchProps<ReferentielDePolynesieResult>
) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        {...props}
        scope="referentiel-de-polynesie"
        scopeExtra={props.scopeExtra}
        minimumInputLength={3}
        transformResults={transformResults}
        transformResult={({ name, id, domain }) => [`${domain}:${id}`, name]}
      />
    </QueryClientProvider>
  );
}
