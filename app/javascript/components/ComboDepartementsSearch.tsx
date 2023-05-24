import React from 'react';
import { matchSorter } from 'match-sorter';

import ComboSearch, { ComboSearchProps } from './ComboSearch';

type DepartementResult = { code: string; nom: string };

const extraTerms = [{ code: '99', nom: 'Etranger' }];

function expandResultsWithForeignDepartement(term: string, result: unknown) {
  const results = result as DepartementResult[];
  return [
    ...results,
    ...matchSorter(extraTerms, term, {
      keys: ['nom', 'code']
    })
  ];
}

type ComboDepartementsSearchProps = Omit<
  ComboSearchProps<DepartementResult> & {
    addForeignDepartement: boolean;
  },
  'transformResult' | 'transformResults'
>;

export function ComboDepartementsSearch({
  addForeignDepartement = true,
  ...props
}: ComboDepartementsSearchProps) {
  return (
    <ComboSearch
      {...props}
      scope="departements"
      minimumInputLength={1}
      transformResult={({ code, nom }) => [code, `${code} - ${nom}`]}
      transformResults={
        addForeignDepartement ? expandResultsWithForeignDepartement : undefined
      }
    />
  );
}
