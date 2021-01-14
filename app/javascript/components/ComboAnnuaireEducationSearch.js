import React from 'react';
import { ReactQueryCacheProvider } from 'react-query';

import ComboSearch from './ComboSearch';
import { queryCache } from './shared/queryCache';

function ComboAnnuaireEducationSearch(params) {
  return (
    <ReactQueryCacheProvider queryCache={queryCache}>
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
    </ReactQueryCacheProvider>
  );
}

export default ComboAnnuaireEducationSearch;
