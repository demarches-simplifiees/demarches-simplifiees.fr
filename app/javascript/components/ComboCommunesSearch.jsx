import React from 'react';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';
import { ComboDepartementsSearch } from './ComboDepartementsSearch';
import { useHiddenField } from './shared/hooks';

// Avoid hiding similar matches for precise queries (like "Sainte Marie")
function searchResultsLimit(term) {
  return term.length > 5 ? 10 : 5;
}

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

const placeholderDepartements = [
  ['63 – Puy-de-Dôme', 'Clermont-Ferrand'],
  ['77 – Seine-et-Marne', 'Melun'],
  ['22 – Côtes d’Armor', 'Saint-Brieuc'],
  ['47 – Lot-et-Garonne', 'Agen']
];
const [placeholderDepartement, placeholderCommune] =
  placeholderDepartements[
    Math.floor(Math.random() * (placeholderDepartements.length - 1))
  ];

function ComboCommunesSearch(params) {
  const [, , hiddenField] = useHiddenField(params.hiddenFieldId);
  const [departementValue, setDepartementValue] = useHiddenField(
    params.hiddenFieldId,
    'departement'
  );
  const [codeDepartement, setCodeDepartement] = useHiddenField(
    params.hiddenFieldId,
    'code_departement'
  );
  const inputId = hiddenField?.id;
  const departementDescribedBy = `${inputId}_departement_notice`;
  const communeDescribedBy = `${inputId}_commune_notice`;

  return (
    <QueryClientProvider client={queryClient}>
      <div>
        <div className="notice" id={departementDescribedBy}>
          <p>
            Choisissez le département dans lequel se situe la commune. Vous
            pouvez entrer le nom ou le code.
          </p>
        </div>
        <ComboDepartementsSearch
          value={departementValue}
          inputId={!codeDepartement ? inputId : null}
          aria-describedby={departementDescribedBy}
          placeholder={placeholderDepartement}
          addForeignDepartement={false}
          required={params.mandatory}
          onChange={(_, result) => {
            setDepartementValue(result?.nom);
            setCodeDepartement(result?.code);
          }}
        />
      </div>
      {codeDepartement ? (
        <div>
          <div className="notice" id={communeDescribedBy}>
            <p>
              Choisissez la commune. Vous pouvez entrer le nom ou le code
              postal.
            </p>
          </div>
          <ComboSearch
            autoFocus
            inputId={inputId}
            aria-describedby={communeDescribedBy}
            placeholder={placeholderCommune}
            required={params.mandatory}
            hiddenFieldId={params.hiddenFieldId}
            scope="communes"
            scopeExtra={codeDepartement}
            minimumInputLength={2}
            transformResult={({ code, nom, codesPostaux }) => [
              code,
              `${nom} (${codesPostaux[0]})`
            ]}
            transformResults={expandResultsWithMultiplePostalCodes}
          />
        </div>
      ) : null}
    </QueryClientProvider>
  );
}

export default ComboCommunesSearch;
