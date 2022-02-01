import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboRegionsSearch(props) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        scope="regions"
        minimumInputLength={0}
        transformResult={({ code, nom }) => [code, nom]}
        {...props}
      />
    </QueryClientProvider>
  );
}

export default ComboRegionsSearch;
