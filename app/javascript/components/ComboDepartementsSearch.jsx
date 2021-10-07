import React from 'react';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

const extraTerms = [{ code: '99', nom: 'Etranger' }];

function expandResultsWithForeignDepartement(term, results) {
  return [
    ...results,
    ...matchSorter(extraTerms, term, {
      keys: ['nom', 'code']
    })
  ];
}

function ComboDepartementsSearch(params) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="departements"
        minimumInputLength={1}
        transformResult={({ code, nom }) => [code, `${code} - ${nom}`]}
        transformResults={expandResultsWithForeignDepartement}
      />
    </QueryClientProvider>
  );
}

export default ComboDepartementsSearch;
