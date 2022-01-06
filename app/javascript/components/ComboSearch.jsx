import React, { useState, useCallback, useRef } from 'react';
import { useDebounce } from 'use-debounce';
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
import invariant from 'tiny-invariant';

import { useDeferredSubmit, useHiddenField, groupId } from './shared/hooks';

function defaultTransformResults(_, results) {
  return results;
}

function ComboSearch({
  onChange,
  value: controlledValue,
  scope,
  scopeExtra,
  minimumInputLength,
  transformResult,
  allowInputValues = false,
  transformResults = defaultTransformResults,
  id,
  describedby,
  ...props
}) {
  invariant(id || onChange, 'ComboSearch: `id` or `onChange` are required');

  const group = !onChange ? groupId(id) : null;
  const [externalValue, setExternalValue, hiddenField] = useHiddenField(group);
  const [, setExternalId] = useHiddenField(group, 'external_id');
  const initialValue = externalValue ? externalValue : controlledValue;
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm] = useDebounce(searchTerm, 300);
  const [value, setValue] = useState(initialValue);
  const resultsMap = useRef({});
  const getLabel = (result) => {
    const [, value, label] = transformResult(result);
    return label ?? value;
  };
  const setExternalValueAndId = useCallback((label) => {
    const { key, value, result } = resultsMap.current[label];
    if (onChange) {
      onChange(value, result);
    } else {
      setExternalId(key);
      setExternalValue(value);
    }
  }, []);
  const awaitFormSubmit = useDeferredSubmit(hiddenField);

  const handleOnChange = useCallback(
    ({ target: { value } }) => {
      setValue(value);
      if (!value) {
        if (onChange) {
          onChange(null);
        } else {
          setExternalId('');
          setExternalValue('');
        }
      } else if (value.length >= minimumInputLength) {
        setSearchTerm(value.trim());
        if (allowInputValues) {
          setExternalId('');
          setExternalValue(value);
        }
      }
    },
    [minimumInputLength]
  );

  const handleOnSelect = useCallback((value) => {
    setExternalValueAndId(value);
    setValue(value);
    setSearchTerm('');
    awaitFormSubmit.done();
  }, []);

  const { isSuccess, data } = useQuery(
    [scope, debouncedSearchTerm, scopeExtra],
    {
      enabled: !!debouncedSearchTerm,
      notifyOnStatusChange: false,
      refetchOnMount: false
    }
  );
  const results = isSuccess ? transformResults(debouncedSearchTerm, data) : [];

  const onBlur = useCallback(() => {
    if (!allowInputValues && isSuccess && results[0]) {
      const label = getLabel(results[0]);
      awaitFormSubmit(() => {
        handleOnSelect(label);
      });
    }
  }, [data]);

  return (
    <Combobox onSelect={handleOnSelect}>
      <ComboboxInput
        {...props}
        onChange={handleOnChange}
        onBlur={onBlur}
        value={value}
        autocomplete={false}
        id={id}
        aria-describedby={describedby}
      />
      {isSuccess && (
        <ComboboxPopover className="shadow-popup">
          {results.length > 0 ? (
            <ComboboxList>
              {results.map((result, index) => {
                const label = getLabel(result);
                const [key, value] = transformResult(result);
                resultsMap.current[label] = { key, value, result };
                return (
                  <ComboboxOption
                    key={`${key}-${index}`}
                    value={label}
                    data-option-value={value}
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
  value: PropTypes.string,
  scope: PropTypes.string,
  minimumInputLength: PropTypes.number,
  transformResult: PropTypes.func,
  transformResults: PropTypes.func,
  allowInputValues: PropTypes.bool,
  onChange: PropTypes.func,
  scopeExtra: PropTypes.string,
  mandatory: PropTypes.bool,
  id: PropTypes.string,
  describedby: PropTypes.string
};

export default ComboSearch;
