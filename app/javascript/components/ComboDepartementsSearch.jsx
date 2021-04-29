import React, { useCallback } from 'react';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

const extraTerms = [{ code: '99', nom: 'Etranger' }];

function ComboDepartementsSearch(params) {
  const transformResults = useCallback((term, results) => [
    ...results,
    ...matchSorter(extraTerms, term, {
      keys: ['nom', 'code']
    })
  ]);

  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="departements"
        minimumInputLength={1}
        transformResult={({ code, nom }) => [code, `${code} - ${nom}`]}
        transformResults={transformResults}
      />
    </QueryClientProvider>
  );
}

export default ComboDepartementsSearch;
