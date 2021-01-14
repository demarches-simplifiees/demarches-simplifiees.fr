import React, { useState, useMemo, useCallback, useRef } from 'react';
import { useDebounce } from 'react-use';
import { useQuery } from 'react-query';
import PropTypes from 'prop-types';
import {
  Combobox,
  ComboboxInput,
  ComboboxPopover,
  ComboboxList,
  ComboboxOption
} from '@reach/combobox';
import '@reach/combobox/styles.css';
import { fire } from '@utils';

function defaultTransformResults(_, results) {
  return results;
}

function ComboSearch({
  placeholder,
  required,
  hiddenFieldId,
  onChange,
  scope,
  minimumInputLength,
  transformResult,
  allowInputValues = false,
  transformResults = defaultTransformResults
}) {
  const label = scope;
  const hiddenField = useMemo(
    () => document.querySelector(`input[data-uuid="${hiddenFieldId}"]`),
    [hiddenFieldId]
  );
  const initialValue = hiddenField && hiddenField.value;
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('');
  const [value, setValue] = useState(initialValue);
  const resultsMap = useRef({});
  const setExternalValue = useCallback((value) => {
    if (hiddenField) {
      hiddenField.setAttribute('value', value);
      fire(hiddenField, 'autosave:trigger');
    }
    if (onChange) {
      const result = resultsMap.current[value];
      onChange(value, result);
    }
  });

  useDebounce(
    () => {
      setDebouncedSearchTerm(searchTerm);
    },
    300,
    [searchTerm]
  );

  const handleOnChange = useCallback(
    ({ target: { value } }) => {
      setValue(value);
      if (value.length >= minimumInputLength) {
        setSearchTerm(value.trim());
        if (allowInputValues) {
          setExternalValue(value);
        }
      }
    },
    [minimumInputLength]
  );

  const handleOnSelect = useCallback((value) => {
    setExternalValue(value);
    setValue(value);
  });

  const { isSuccess, data } = useQuery([scope, debouncedSearchTerm], {
    enabled: !!debouncedSearchTerm,
    notifyOnStatusChange: false,
    refetchOnMount: false
  });
  const results = isSuccess ? transformResults(debouncedSearchTerm, data) : [];

  return (
    <Combobox aria-label={label} onSelect={handleOnSelect}>
      <ComboboxInput
        placeholder={placeholder}
        onChange={handleOnChange}
        value={value}
        required={required}
      />
      {isSuccess && (
        <ComboboxPopover className="shadow-popup">
          {results.length > 0 ? (
            <ComboboxList>
              {results.map((result) => {
                const [key, str] = transformResult(result);
                resultsMap.current[str] = result;
                return (
                  <ComboboxOption
                    key={key}
                    value={str}
                    data-option-value={str}
                  />
                );
              })}
            </ComboboxList>
          ) : (
            <span style={{ display: 'block', margin: 8 }}>
              Aucun résultat trouvé
            </span>
          )}
        </ComboboxPopover>
      )}
    </Combobox>
  );
}

ComboSearch.propTypes = {
  placeholder: PropTypes.string,
  required: PropTypes.bool,
  hiddenFieldId: PropTypes.string,
  scope: PropTypes.string,
  minimumInputLength: PropTypes.number,
  transformResult: PropTypes.func,
  transformResults: PropTypes.func,
  allowInputValues: PropTypes.bool,
  onChange: PropTypes.func
};

export default ComboSearch;
