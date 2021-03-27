import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboRegionsSearch(params) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="regions"
        minimumInputLength={0}
        transformResult={({ code, nom }) => [code, nom]}
      />
    </QueryClientProvider>
  );
}

export default ComboRegionsSearch;
