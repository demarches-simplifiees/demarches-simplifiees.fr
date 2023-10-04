import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

type TableRowSelectorResult = {
  name: string;
  id: string;
  domain: string;
};

function transformResults(_: unknown, result: unknown) {
  return result as TableRowSelectorResult[];
}

export default function ComboTableRowSelectorSearch(
  props: ComboSearchProps<TableRowSelectorResult>
) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        {...props}
        scope="table-row-selector"
        scopeExtra={props.scopeExtra}
        minimumInputLength={3}
        transformResults={transformResults}
        transformResult={({ name, id, domain }) => [`${domain}:${id}`, name]}
      />
    </QueryClientProvider>
  );
}
