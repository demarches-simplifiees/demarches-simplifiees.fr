import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

export default function ComboPaysSearch(
  props: ComboSearchProps<{ code: string; value: string; label: string }>
) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        {...props}
        scope="pays"
        minimumInputLength={0}
        transformResult={({ code, value, label }) => [code, value, label]}
      />
    </QueryClientProvider>
  );
}
