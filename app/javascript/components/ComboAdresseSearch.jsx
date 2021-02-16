import React, { useCallback } from 'react';
import { QueryClientProvider } from 'react-query';
import PropTypes from 'prop-types';

import ComboSearch from './ComboSearch';
import { queryClient } from './shared/queryClient';

function ComboAdresseSearch({
  mandatory,
  placeholder,
  hiddenFieldId,
  onChange,
  transformResult = ({ properties: { label } }) => [label, label],
  allowInputValues = true
}) {
  const transformResults = useCallback((_, { features }) => features);

  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch
        placeholder={placeholder}
        required={mandatory}
        hiddenFieldId={hiddenFieldId}
        onChange={onChange}
        allowInputValues={allowInputValues}
        scope="adresse"
        minimumInputLength={2}
        transformResult={transformResult}
        transformResults={transformResults}
      />
    </QueryClientProvider>
  );
}

ComboAdresseSearch.propTypes = {
  placeholder: PropTypes.string,
  mandatory: PropTypes.bool,
  hiddenFieldId: PropTypes.string,
  transformResult: PropTypes.func,
  allowInputValues: PropTypes.bool,
  onChange: PropTypes.func
};

export default ComboAdresseSearch;
