import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboPaysSearch(params) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="pays"
        minimumInputLength={0}
        transformResult={({ nom }) => [nom, nom]}
      />
    </QueryClientProvider>
  );
}

export default ComboPaysSearch;
