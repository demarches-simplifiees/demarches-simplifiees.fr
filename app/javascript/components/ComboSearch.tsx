import React, { useState, useRef, ChangeEventHandler } from 'react';
import { useDebounce } from 'use-debounce';
import { useQuery } from 'react-query';
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

type TransformResults<Result> = (term: string, results: unknown) => Result[];
type TransformResult<Result> = (
  result: Result
) => [key: string, value: string, label?: string];

export type ComboSearchProps<Result> = {
  onChange?: (value: string | null, result?: Result) => void;
  value?: string;
  scope: string;
  scopeExtra?: string;
  minimumInputLength: number;
  transformResults?: TransformResults<Result>;
  transformResult: TransformResult<Result>;
  allowInputValues?: boolean;
  id?: string;
  describedby?: string;
  className?: string;
  placeholder?: string;
};

type QueryKey = readonly [
  scope: string,
  term: string,
  extra: string | undefined
];

function ComboSearch<Result>({
  onChange,
  value: controlledValue,
  scope,
  scopeExtra,
  minimumInputLength,
  transformResult,
  allowInputValues = false,
  transformResults = (_, results) => results as Result[],
  id,
  describedby,
  ...props
}: ComboSearchProps<Result>) {
  invariant(id || onChange, 'ComboSearch: `id` or `onChange` are required');

  const group = !onChange && id ? groupId(id) : undefined;
  const [externalValue, setExternalValue, hiddenField] = useHiddenField(group);
  const [, setExternalId] = useHiddenField(group, 'external_id');
  const initialValue = externalValue ? externalValue : controlledValue;
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm] = useDebounce(searchTerm, 300);
  const [value, setValue] = useState(initialValue);
  const resultsMap = useRef<
    Record<string, { key: string; value: string; result: Result }>
  >({});
  const getLabel = (result: Result) => {
    const [, value, label] = transformResult(result);
    return label ?? value;
  };
  const setExternalValueAndId = (label: string) => {
    const { key, value, result } = resultsMap.current[label];
    if (onChange) {
      onChange(value, result);
    } else {
      setExternalId(key);
      setExternalValue(value);
    }
  };
  const awaitFormSubmit = useDeferredSubmit(hiddenField);

  const handleOnChange: ChangeEventHandler<HTMLInputElement> = ({
    target: { value }
  }) => {
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
  };

  const handleOnSelect = (value: string) => {
    setExternalValueAndId(value);
    setValue(value);
    setSearchTerm('');
    awaitFormSubmit.done();
  };

  const { isSuccess, data } = useQuery<void, void, unknown, QueryKey>(
    [scope, debouncedSearchTerm, scopeExtra],
    {
      enabled: !!debouncedSearchTerm,
      refetchOnMount: false
    }
  );
  const results =
    isSuccess && data ? transformResults(debouncedSearchTerm, data) : [];

  const onBlur = () => {
    if (!allowInputValues && isSuccess && results[0]) {
      const label = getLabel(results[0]);
      awaitFormSubmit(() => {
        handleOnSelect(label);
      });
    }
  };

  return (
    <Combobox onSelect={handleOnSelect}>
      <ComboboxInput
        {...props}
        onChange={handleOnChange}
        onBlur={onBlur}
        value={value ?? ''}
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
                return <ComboboxOption key={`${key}-${index}`} value={label} />;
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

export default ComboSearch;
