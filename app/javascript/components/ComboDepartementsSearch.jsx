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

export function ComboDepartementsSearch(params) {
  return (
    <ComboSearch
      {...params}
      scope="departements"
      minimumInputLength={1}
      transformResult={({ code, nom }) => [code, `${code} - ${nom}`]}
      transformResults={expandResultsWithForeignDepartement}
    />
  );
}

function ComboDepartementsSearchDefault(params) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboDepartementsSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
      />
    </QueryClientProvider>
  );
}

export default ComboDepartementsSearchDefault;
