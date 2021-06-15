import React from 'react';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function expandResultsWithMultiplePostalCodes(term, results) {
  const expandedResults = results.flatMap((result) =>
    result.codesPostaux.map((codePostal) => ({
      ...result,
      codesPostaux: [codePostal]
    }))
  );
  const limit = term.length > 5 ? 10 : 5;
  if (expandedResults.length > limit) {
    return matchSorter(expandedResults, term, {
      keys: [(item) => `${item.nom} (${item.codesPostaux[0]})`, 'code'],
      sorter: (rankedItems) => rankedItems
    }).slice(0, limit + 1);
  }

  return expandedResults;
}

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
        transformResults={expandResultsWithMultiplePostalCodes}
      />
    </QueryClientProvider>
  );
}

export default ComboCommunesSearch;
