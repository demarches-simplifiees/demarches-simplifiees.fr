import React, { useCallback } from 'react';
import { QueryClientProvider } from 'react-query';
import PropTypes from 'prop-types';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboAdresseSearch({
  transformResult = ({ properties: { label } }) => [label, label],
  allowInputValues = true,
  ...props
}) {
  const transformResults = useCallback((_, { features }) => features);

  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        allowInputValues={allowInputValues}
        scope="adresse"
        minimumInputLength={2}
        transformResult={transformResult}
        transformResults={transformResults}
        {...props}
      />
    </QueryClientProvider>
  );
}

ComboAdresseSearch.propTypes = {
  transformResult: PropTypes.func,
  allowInputValues: PropTypes.bool
};

export default ComboAdresseSearch;
