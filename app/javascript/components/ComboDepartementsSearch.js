import React, { useCallback } from 'react';
import { ReactQueryCacheProvider } from 'react-query';
import matchSorter from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryCache } from './shared/queryCache';

const extraTerms = [{ code: '99', nom: 'Etranger' }];

function ComboDepartementsSearch(params) {
  const transformResults = useCallback((term, results) => [
    ...results,
    ...matchSorter(extraTerms, term, {
      keys: ['nom', 'code']
    })
  ]);

  return (
    <ReactQueryCacheProvider queryCache={queryCache}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="departements"
        minimumInputLength={1}
        transformResult={({ code, nom }) => [code, `${code} - ${nom}`]}
        transformResults={transformResults}
      />
    </ReactQueryCacheProvider>
  );
}

export default ComboDepartementsSearch;
