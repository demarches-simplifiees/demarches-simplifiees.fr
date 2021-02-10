import React from 'react';
import { ReactQueryCacheProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryCache } from './shared/queryCache';

function ComboCommunesSearch(params) {
  return (
    <ReactQueryCacheProvider queryCache={queryCache}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="communes"
        minimumInputLength={2}
        transformResult={({ code, nom, codesPostaux }) => [
          code,
          `${nom} (${codesPostaux[0]})`
        ]}
      />
    </ReactQueryCacheProvider>
  );
}

export default ComboCommunesSearch;
