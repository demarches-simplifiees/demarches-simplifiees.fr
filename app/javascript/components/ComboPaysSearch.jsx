import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboPaysSearch(props) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        scope="pays"
        minimumInputLength={0}
        transformResult={({ code, value, label }) => [code, value, label]}
        {...props}
      />
    </QueryClientProvider>
  );
}

export default ComboPaysSearch;
