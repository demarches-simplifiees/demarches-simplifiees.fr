import React from 'react';
import { ReactQueryCacheProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryCache } from './shared/queryCache';

function ComboRegionsSearch(params) {
  return (
    <ReactQueryCacheProvider queryCache={queryCache}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="regions"
        minimumInputLength={0}
        transformResult={({ code, nom }) => [code, nom]}
      />
    </ReactQueryCacheProvider>
  );
}

export default ComboRegionsSearch;
