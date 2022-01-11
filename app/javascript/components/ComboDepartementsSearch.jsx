import React from 'react';
import PropTypes from 'prop-types';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

const extraTerms = [{ code: '99', nom: 'Etranger' }];

function expandResultsWithForeignDepartement(term, results) {
  return [
    ...results,
    ...matchSorter(extraTerms, term, {
      keys: ['nom', 'code']
    })
  ];
}

export function ComboDepartementsSearch({
  addForeignDepartement = true,
  ...params
}) {
  return (
    <ComboSearch
      {...params}
      scope="departements"
      minimumInputLength={1}
      transformResult={({ code, nom }) => [code, `${code} - ${nom}`]}
      transformResults={
        addForeignDepartement ? expandResultsWithForeignDepartement : undefined
      }
    />
  );
}

function ComboDepartementsSearchDefault(params) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboDepartementsSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
      />
    </QueryClientProvider>
  );
}

ComboDepartementsSearch.propTypes = {
  ...ComboSearch.propTypes,
  addForeignDepartement: PropTypes.bool
};

export default ComboDepartementsSearchDefault;
