import React from 'react';
import { QueryClientProvider } from 'react-query';
import { matchSorter } from 'match-sorter';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

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

export default function ComboDepartementsSearchDefault(
  params: ComboDepartementsSearchProps
) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboDepartementsSearch {...params} />
    </QueryClientProvider>
  );
}
