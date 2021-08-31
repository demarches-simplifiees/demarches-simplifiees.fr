import React, { useState, useMemo, useCallback, useRef } from 'react';
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
import { fire } from '@utils';

import { useDeferredSubmit } from './shared/hooks';

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
  transformResults = defaultTransformResults,
  className
}) {
  const label = scope;
  const hiddenValueField = useMemo(
    () => document.querySelector(`input[data-uuid="${hiddenFieldId}"]`),
    [hiddenFieldId]
  );
  const hiddenIdField = useMemo(
    () =>
      document.querySelector(
        `input[data-uuid="${hiddenFieldId}"] + input[data-reference]`
      ),
    [hiddenFieldId]
  );
  const initialValue = hiddenValueField && hiddenValueField.value;
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm] = useDebounce(searchTerm, 300);
  const [value, setValue] = useState(initialValue);
  const resultsMap = useRef({});
  const getLabel = (result) => {
    const [, value, label] = transformResult(result);
    return label ?? value;
  };
  const setExternalValue = useCallback(
    (value) => {
      if (hiddenValueField) {
        hiddenValueField.setAttribute('value', value);
        fire(hiddenValueField, 'autosave:trigger');
      }
    },
    [hiddenValueField]
  );
  const setExternalId = useCallback(
    (key) => {
      if (hiddenIdField) {
        hiddenIdField.setAttribute('value', key);
      }
    },
    [hiddenIdField]
  );
  const setExternalValueAndId = useCallback((label) => {
    const { key, value, result } = resultsMap.current[label];
    setExternalId(key);
    setExternalValue(value);
    if (onChange) {
      onChange(value, result);
    }
  }, []);
  const awaitFormSubmit = useDeferredSubmit(hiddenValueField);

  const handleOnChange = useCallback(
    ({ target: { value } }) => {
      setValue(value);
      if (value.length >= minimumInputLength) {
        setSearchTerm(value.trim());
        if (allowInputValues) {
          setExternalId('');
          setExternalValue(value);
        }
      } else if (!value) {
        setExternalId('');
        setExternalValue('');
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

  const { isSuccess, data } = useQuery([scope, debouncedSearchTerm], {
    enabled: !!debouncedSearchTerm,
    notifyOnStatusChange: false,
    refetchOnMount: false
  });
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
    <Combobox aria-label={label} onSelect={handleOnSelect}>
      <ComboboxInput
        className={className}
        placeholder={placeholder}
        onChange={handleOnChange}
        onBlur={onBlur}
        value={value}
        required={required}
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
  placeholder: PropTypes.string,
  required: PropTypes.bool,
  hiddenFieldId: PropTypes.string,
  scope: PropTypes.string,
  minimumInputLength: PropTypes.number,
  transformResult: PropTypes.func,
  transformResults: PropTypes.func,
  allowInputValues: PropTypes.bool,
  onChange: PropTypes.func,
  className: PropTypes.string
};

export default ComboSearch;
