import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

export default function ComboRegionsSearch(
  props: ComboSearchProps<{ code: string; nom: string }>
) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        {...props}
        scope="regions"
        minimumInputLength={0}
        transformResult={({ code, nom }) => [code, nom]}
      />
    </QueryClientProvider>
  );
}
