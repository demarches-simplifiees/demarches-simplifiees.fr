import React from 'react';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryClient, searchResultsLimit } from './shared/queryClient';

function expandResultsWithMultiplePostalCodes(term, results) {
  // A single result may have several associated postal codes.
  // To make the search results more precise, we want to generate
  // an actual result for each postal code.
  const expandedResults = results.flatMap((result) =>
    result.codesPostaux.map((codePostal) => ({
      ...result,
      codesPostaux: [codePostal]
    }))
  );

  // Some very large cities (like Paris) have A LOT of associated postal codes.
  // As we generated one result per postal code, we now have a lot of results
  // for the same city. If the number of results is above the threshold, we use
  // local search to narrow the results.
  const limit = searchResultsLimit(term);
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
