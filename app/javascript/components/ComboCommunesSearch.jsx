import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboCommunesSearch(params) {
  return (
    <QueryClientProvider client={queryClient}>
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
    </QueryClientProvider>
  );
}

export default ComboCommunesSearch;
