import React from 'react';
import { QueryClientProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboAnnuaireEducationSearch(params) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        required={params.mandatory}
        hiddenFieldId={params.hiddenFieldId}
        scope="annuaire-education"
        minimumInputLength={3}
        transformResults={(_, { records }) => records}
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

export default ComboAnnuaireEducationSearch;
