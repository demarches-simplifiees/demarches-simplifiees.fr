import React from 'react';
import { ReactQueryCacheProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryCache } from './shared/queryCache';

function ComboPaysSearch(params) {
  return (
    <ReactQueryCacheProvider queryCache={queryCache}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="pays"
        minimumInputLength={0}
        transformResult={({ nom }) => [nom, nom]}
      />
    </ReactQueryCacheProvider>
  );
}

export default ComboPaysSearch;
