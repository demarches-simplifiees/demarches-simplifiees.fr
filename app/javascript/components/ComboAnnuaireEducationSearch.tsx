import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

type AnnuaireEducationResult = {
  fields: {
    identifiant_de_l_etablissement: string;
    nom_etablissement: string;
    nom_commune: string;
  };
};

function transformResults(_: unknown, result: unknown) {
  const results = result as { records: AnnuaireEducationResult[] };
  return results.records as AnnuaireEducationResult[];
}

export default function ComboAnnuaireEducationSearch(
  props: ComboSearchProps<AnnuaireEducationResult>
) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        {...props}
        scope="annuaire-education"
        minimumInputLength={3}
        transformResults={transformResults}
        transformResult={({
          fields: {
            identifiant_de_l_etablissement: id,
            nom_etablissement,
            nom_commune
          }
        }) => [id, `${nom_etablissement}, ${nom_commune} (${id})`]}
      />
    </QueryClientProvider>
  );
}
